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
# Colours
#####################################

C_BACKGROUND="\033[48;5;16m"
C_RED="\033[38;5;9m${C_BACKGROUND}"
C_PINK="\033[38;5;206m${C_BACKGROUND}"
C_CYAN="\033[38;5;87m${C_BACKGROUND}"
C_BLUE="\033[38;5;45m${C_BACKGROUND}"
C_WHITE="\033[38;5;15m${C_BACKGROUND}"
C_GREEN="\033[38;5;46m${C_BACKGROUND}"
C_RESET="\033[0m${C_BACKGROUND}"
C_YELLOW="\033[38;5;226m${C_BACKGROUND}"

#####################################
# Functions
#####################################

function copy_files_flat {
  local name="$1"
  local dest="$2"
  shift 2
  local files=("$@")
  local total=${#files[@]}
  local counter=1
  local copied=0

  for f in "${files[@]}"; do
    base=$(basename "$f")
    printf '\r\033[K[%d/%d] %s: %s' "$counter" "$total" "$name" "$base"
    if [[ -e "$dest/$base" ]]; then
      echo -e "\nWARNING: duplicate $name skipped: $base"
    else
      cp "$f" "$dest"
      ((copied++))
    fi
    ((counter++))
  done
  echo "" # final newline
  echo "$copied of $total $name files copied"
}

function copy_files_merge_symbols {
  local dest="$1"
  shift
  local files=("$@")
  local total=${#files[@]}
  echo "Merging $total symbol files into $dest"

  # header from first file
  awk 'NR==1,/^\)/' "${files[0]}" > "$dest"

  for f in "${files[@]}"; do
    awk '/^\(symbol /{in_symbol=1} in_symbol{print}' "$f" >> "$dest"
  done
  echo ")" >> "$dest"
}

function copy_files_preserve_dirs {
  local name="$1"
  local dest="$2"
  shift 2
  local files=("$@")
  local total=${#files[@]}
  local counter=1
  local copied=0

  for f in "${files[@]}"; do
    rel="${f#$SRC_DIR/}"
    printf '\r\033[K[%d/%d] %s: %s' "$counter" "$total" "$name" "$(basename "$f")"
    mkdir -p "$dest/$(dirname "$rel")"
    cp "$f" "$dest/$rel"
    ((copied++))
    ((counter++))
  done
  echo "" # final newline
  echo "$copied of $total $name files copied"
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

copy_files_flat "Footprint" "$FP_DIR" "${footprint_files[@]}"
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
  copy_files_merge_symbols "$SYM_OUT" "${symbol_files[@]}"
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

copy_files_preserve_dirs "3D model" "$MODEL_DIR" "${model_files[@]}"

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
