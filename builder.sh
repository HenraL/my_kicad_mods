#!/usr/bin/env bash
# Original script written partially by hand
# Script writing was aided by AI.
set -euo pipefail

SRC_DIR="src"
BUILD_DIR="build"

FP_DIR="$BUILD_DIR/footprints/Misc.pretty"
SYM_DIR="$BUILD_DIR/symbols"
SYM_OUT="$SYM_DIR/Combined.kicad_sym"
MODEL_DIR="$BUILD_DIR/3dmodels"
MODEL_VAR="MY_3DMODELS"

#####################################
# Functions
#####################################

function copy_across {
  local operation_name="$1"
  local destination="$2"
  shift 2
  local source="$@"
  local total=${#source[@]}
  local counter=1
  local copied=0
  for file in "${source[@]}"
  do
    rel=$(basename "$file" | tr -d '\n')
    printf '\r\033[K[%d/%d] %s: %s' "$counter" "$total" "$operation_name" "$rel"
    if [[ -e "$dest/$file" ]]; then
      echo -e "\nWARNING: duplicate $operation_name skipped: $file"
      let "copied=$copied+1"
    else
      cp "$file" "$dest"
    fi
    let "counter=$counter+1"
  done
  echo "" # New line after all the files have been copied
  echo "Copied $copied of $total file(s)"
}

function copy_across_3D {
  local operation_name="3D model"
  local destination="$1"
  shift 1
  local source="$@"
  local total=${#source[@]}
  local counter=1
  local copied=0
  for file in "${source[@]}"
  do
    rel=$(basename "$file" | tr -d '\n')

    printf '\r\033[KCopying footprint %d of %d: %s' "$counter" "$total" "$rel"
    if [[ -e "$dest/$file" ]]; then
      echo -e "\nWARNING: duplicate $operation_name skipped: $file"
      let "copied=$copied+1"
    else
      cp "$file" "$dest"
    fi
    let "counter=$counter+1"
  done
  echo "" # New line after all the files have been copied
  echo "Copied $copied of $total file(s)"
}

#####################################
# Boot up
#####################################

echo "=============================================="
echo " KiCad Library Build Script"
echo "=============================================="
echo ""
echo "IMPORTANT:"
echo "  This script DOES NOT override any KiCad paths."
echo "  You will ADD a new 3D model path variable."
echo ""
echo "  Variable name : $MODEL_VAR"
echo "  Variable path : (absolute path to) $MODEL_DIR"
echo ""
echo "DO NOT modify KICAD*_3DMODEL_DIR variables."
echo ""

#######################################
# Clean + setup
#######################################
echo "Cleaning previous build..."
rm -rf "$BUILD_DIR"

echo "Creating build directories..."
mkdir -p "$FP_DIR" "$SYM_DIR" "$MODEL_DIR"

#######################################
# Footprints
#######################################
echo ""
echo "Collecting footprint files (.kicad_mod)..."
mapfile -t footprint_files < <(find "$SRC_DIR" -name "*.kicad_mod" | sort)
num_fp=${#footprint_files[@]}
echo "Found $num_fp footprints."

# counter=1
# for file in "${footprint_files[@]}"; do
#   name=$(basename "$file")
#   dest="$FP_DIR/$name"

#   printf '\r\033[K[%d/%d] Footprint: %s' "$counter" "$num_fp" "$name"

#   if [[ -e "$dest" ]]; then
#     echo -e "\nWARNING: duplicate footprint skipped: $name"
#   else
#     cp "$file" "$dest"
#   fi

#   ((counter++))
# done
copy_across "footprint" "$FP_DIR" "${footprint_files[@]}"
echo -e "\nFootprints done."

#######################################
# Symbols (merged)
#######################################
echo ""
echo "Collecting symbol files (.kicad_sym)..."
mapfile -t symbol_files < <(find "$SRC_DIR" -name "*.kicad_sym" | sort)
num_sym=${#symbol_files[@]}
echo "Found $num_sym symbol files."

if (( num_sym > 0 )); then
  echo "Merging symbols into ONE library:"
  echo "  $SYM_OUT"

  awk 'NR==1,/^\)/' "${symbol_files[0]}" > "$SYM_OUT"

  for file in "${symbol_files[@]}"; do
    awk '
      /^\(symbol / {in_symbol=1}
      in_symbol {print}
    ' "$file" >> "$SYM_OUT"
  done

  echo ")" >> "$SYM_OUT"
else
  echo "No symbols found."
fi

#######################################
# 3D models
#######################################
echo ""
echo "Collecting 3D models (.wrl / .step / .stp)..."
mapfile -t model_files < <(
  find "$SRC_DIR" -type f \( -iname "*.wrl" -o -iname "*.step" -o -iname "*.stp" \) | sort
)
num_models=${#model_files[@]}
echo "Found $num_models model files."

counter=1
for file in "${model_files[@]}"; do
  rel="${file#$SRC_DIR/}"
  dest="$MODEL_DIR/$rel"

  printf '\r\033[K[%d/%d] 3D model: %s' "$counter" "$num_models" "$(basename "$file")"

  mkdir -p "$(dirname "$dest")"
  cp "$file" "$dest"

  ((counter++))
done
echo -e "\n3D models done."

#######################################
# Final instructions (VERY explicit)
#######################################
echo ""
echo "=============================================="
echo " BUILD COMPLETE"
echo "=============================================="
echo "Build completed successfully."
echo ""
echo "Import into KiCad:"
echo "  Footprints : $FP_DIR"
echo "  Symbols    : $SYM_OUT"
echo "  3D models  : set path to $MODEL_DIR"
echo ""
echo "NOW DO THIS IN KiCad (ONCE):"
echo ""
echo "1) Footprints:"
echo "   Preferences → Manage Footprint Libraries"
echo "   Add this library:"
echo "     $FP_DIR"
echo ""
echo "2) Symbols:"
echo "   Preferences → Manage Symbol Libraries"
echo "   Add this file:"
echo "     $SYM_OUT"
echo ""
echo "3) 3D Models (IMPORTANT):"
echo "   Preferences → Configure Paths"
echo ""
echo "   ADD a NEW variable (do NOT edit existing ones):"
echo ""
echo "     Name : $MODEL_VAR"
echo "     Path : $(cd "$MODEL_DIR" && pwd)"
echo ""
echo "   DO NOT modify KICAD*_3DMODEL_DIR"
echo ""
echo "Once this is done, KiCad will automatically find"
echo "all 3D models produced by this script."
echo ""
echo "=============================================="
echo "(c) Written by Henry Letellier, aided by AI"
