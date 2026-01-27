#!/usr/bin/env bash
# Original script written partially by hand
# Script writing was aided by AI.
# set -euo pipefail
set -uo pipefail

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
# Troublemakers (for IP reasons)
#####################################
EXCLUDE_PATHS=("ultra_librarian")

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
  local warning="${C_YELLOW}"

  for f in "${files[@]}"; do
    base=$(basename "$f")
    printf "\r\033[K%b[%d/%d] %s: %s%b" "$C_BLUE" "$counter" "$total" "$name" "${base//%/%%}" "$C_RESET"
    if [[ -e "$dest/$base" ]]; then
      warning="$warning\nWARNING: duplicate $name skipped: $base"
    else
      cp "$f" "$dest"
      ((copied++))
    fi
    ((counter++))
  done
  echo "" # final newline
  echo -e "$warning${C_RESET}"
  echo -e "${C_GREEN}$copied of $total $name files copied${C_RESET}"
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

function copy_3dshape_dirs {
  local dest="$1"
  shift
  local dirs=("$@")
  local total=${#dirs[@]}
  local counter=1
  local copied=0
  local warning="${C_YELLOW}"
  local name=""

  for d in "${dirs[@]}"; do
    name="$(basename "$d")"
    printf "\r\033[K%b[%d/%d] %s: %s%b" "$C_BLUE" "$counter" "$total" "3D model" "${name//%/%%}" "$C_RESET"
    if [[ -e "$dest/$name" ]]
    then
      warning="$warning\nWARNING: Duplicate 3D model skipped: $name"
    else
      cp -r "$d" "$dest"
      ((copied++))
    fi
    ((counter++))
  done
  echo -e "$warning${C_RESET}"
  echo -e "${C_GREEN}$copied of $total 3D models copied${C_RESET}"
}

# Functions for handling troublemakers

function compile_troublemakers {
  local PRUNE_EXPR=""
  for excl in "${EXCLUDE_PATHS[@]}"; do
    PRUNE_EXPR="$PRUNE_EXPR -path */$excl/* -prune -o"
  done
  echo "$PRUNE_EXPR"
}

function handle_troublemakers {
  local type="$1"       # "footprint" / "symbol" / "3D"
  local src_dir="$2"    # src root
  local out_dir="$3"    # build root for this type
  shift 3
  local providers=("$@") # EXCLUDE_PATHS

  for provider in "${providers[@]}"; do
    echo -e "${C_YELLOW}Processing $type from provider: $provider${C_RESET}"

    case "$type" in
      "footprint")
        # Collect .kicad_mod files under provider
        mapfile -t files < <(find "$src_dir" -path "*/$provider/*" -name "*.kicad_mod" | sort)
        if (( ${#files[@]} > 0 )); then
          dest="$out_dir/${provider}.pretty"
          mkdir -p "$dest"
          copy_files_flat "Footprint" "$dest" "${files[@]}"
        fi
        ;;

      "symbol")
        # Collect .kicad_sym files under provider
        mapfile -t files < <(find "$src_dir" -path "*/$provider/*" -name "*.kicad_sym" | sort)
        if (( ${#files[@]} > 0 )); then
          dest="$out_dir/${provider}.kicad_sym"
          copy_files_merge_symbols "$dest" "${files[@]}"
        fi
        ;;

      "3D")
        # Collect .3dshapes folders under provider
        mapfile -t dirs < <(find "$src_dir" -path "*/$provider/*" -type d -name "*.3dshapes" | sort)
        if (( ${#dirs[@]} > 0 )); then
          dest="$out_dir/$provider"
          mkdir -p "$dest"
          copy_3dshape_dirs "$dest" "${dirs[@]}"
        fi
        ;;

      *)
        echo -e "${C_RED}Unknown type: $type${C_RESET}"
        ;;
    esac
  done
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

PRUNE_DIRS=$(compile_troublemakers)

#######################################
# Clean + setup
#######################################
echo -e "${C_PINK}Cleaning previous build...${C_RESET}"
rm -rf "$BUILD_DIR"

echo -e "${C_PINK}Creating build directories...${C_RESET}"
mkdir -p "$FP_DIR" "$SYM_DIR" "$MODEL_DIR"

#######################################
# Footprints
#######################################
echo ""
echo -e "${C_CYAN}Collecting footprint files (.kicad_mod)...${C_RESET}"
mapfile -t footprint_files < <(find "$SRC_DIR" -name "*.kicad_mod" $PRUNE_DIRS | sort)
num_fp=${#footprint_files[@]}
echo -e "${C_GREEN}Found $num_fp footprints.${C_RESET}"

copy_files_flat "Footprint" "$FP_DIR" "${footprint_files[@]}"
echo -e "\n${C_GREEN}Footprints done.${C_RESET}"

#######################################
# Symbols (merged)
#######################################
echo ""
echo -e "${C_CYAN}Collecting symbol files (.kicad_sym)...${C_RESET}"
mapfile -t symbol_files < <(find "$SRC_DIR" -name "*.kicad_sym" $PRUNE_DIRS | sort)
num_sym=${#symbol_files[@]}
echo -e "${C_GREEN}Found $num_sym symbol files.${C_RESET}"

if (( num_sym > 0 )); then
  copy_files_merge_symbols "$SYM_OUT" "${symbol_files[@]}"
else
  echo -e "${C_RED}No symbols found.${C_RESET}"
fi

#######################################
# 3D models
#######################################
echo ""
echo -e "${C_CYAN}Collecting 3D models (.3dshapes)...${C_RESET}"
mapfile -t model_dirs < <(
  find "$SRC_DIR" -type d -name "*.3dshapes" $PRUNE_DIRS | sort
)
num_models=${#model_dirs[@]}
echo -e "${C_GREEN}Found $num_models model files.${C_RESET}"

copy_3dshape_dirs "$MODEL_DIR" "${model_dirs[@]}"

echo -e "\n${C_GREEN}3D models done.${C_RESET}"

#####################################
# Handle "troublemaker" libraries
#####################################

echo -e "${C_RED}Processing troublemaker libraries${C_RESET}"
handle_troublemakers "footprint" "$SRC_DIR" "$BUILD_DIR/footprints" "${EXCLUDE_PATHS[@]}"
handle_troublemakers "symbol"    "$SRC_DIR" "$BUILD_DIR/symbols"    "${EXCLUDE_PATHS[@]}"
handle_troublemakers "3D"        "$SRC_DIR" "$BUILD_DIR/3dmodels"   "${EXCLUDE_PATHS[@]}"
echo -e "${C_GREEN}Troublemakers processed${C_RESET}"

#######################################
# Final instructions (VERY explicit)
#######################################
echo -e "${C_GREEN}"
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
echo -e "${C_YELLOW}NOW DO THIS IN KiCad (ONCE):"
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
echo -e "${C_RED}   DO NOT modify KICAD*_3DMODEL_DIR${C_RESET}"
echo -e "${C_CYAN}"
echo "Once this is done, KiCad will automatically find"
echo "all 3D models produced by this script."
echo ""
echo -e "==============================================${C_RESET}"
echo "(c) Written by Henry Letellier, aided by AI"
