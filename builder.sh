#!/usr/bin/env bash
# Original script written partially by hand
# Script writing was aided by AI.
# set -euo pipefail
set -uo pipefail

#####################################
# Timer tracking - initialise
#####################################
RUN_START_TIME=$(date +%s)
ELAPSED_TIME=0
ELAPSED_HOURS=0
ELAPSED_MINUTES=0
ELAPSED_SECONDS=0
PRETTY_LOG_ELAPSED=""

SRC_DIR="src"
BUILD_DIR="build"

#####################################
# Output destinations
#####################################

FP_DIR="$BUILD_DIR/footprints/Misc.pretty"
SYM_DIR="$BUILD_DIR/symbols"
SYM_OUT="$SYM_DIR/Combined.kicad_sym"
MODEL_DIR="$BUILD_DIR/3dmodels"
MODEL_VAR="MY_3DMODELS"

#####################################
# Troublemakers (for IP reasons)
#####################################
EXCLUDE_PATHS=("ultra_librarian")

####################################
# Refresh rate for output on screen
####################################
OUTPUT_REFRESH_RATE=10

####################################
# Some booleans
####################################
TRUE=0
FALSE=1
YES=$TRUE
NO=$FALSE

#####################################
# In a Terminal ?
#####################################

if [[ -t 1 ]];then
  echo "We are in a terminal"
  IS_A_TTY=$TRUE
else
  echo "We are not in a terminal"
  IS_A_TTY=$FALSE
fi

#####################################
# Troublemaker patterns check
#####################################

if [[ "$IS_A_TTY" == "$FALSE" ]]; then
  if [[ -v ADVANCED_CHOICE_OVERRIDE ]]; then 
    printf "Compiling troublemaker patterns for ADVANCED_CHOICE_OVERRIDE=%d " "$ADVANCED_CHOICE_OVERRIDE"
  fi
  if [[ -v PATTERN_CHOICE_OVERRIDE ]]; then
    printf "Compiling troublemaker patterns for PATTERN_CHOICE_OVERRIDE= %d\n" "$PATTERN_CHOICE_OVERRIDE"
  fi
fi

#####################################
# Colours
#####################################

if [[ "$IS_A_TTY" == "$FALSE" ]]; then
  C_BACKGROUND=""
  C_RED=""
  C_PINK=""
  C_CYAN=""
  C_BLUE=""
  C_WHITE=""
  C_GREEN=""
  C_RESET=""
  C_YELLOW=""
else
  C_BACKGROUND="\033[48;5;16m"
  C_RED="\033[38;5;9m${C_BACKGROUND}"
  C_PINK="\033[38;5;206m${C_BACKGROUND}"
  C_CYAN="\033[38;5;87m${C_BACKGROUND}"
  C_BLUE="\033[38;5;45m${C_BACKGROUND}"
  C_WHITE="\033[38;5;15m${C_BACKGROUND}"
  C_GREEN="\033[38;5;46m${C_BACKGROUND}"
  C_RESET="\033[0m${C_BACKGROUND}"
  C_YELLOW="\033[38;5;226m${C_BACKGROUND}"
fi

#####################################
# Functions
#####################################

# Fancy displaying and artificial output reduction (avoids slowing down the program via excessive outputs)
function update_elapsed_time {
  local i=$1
  if (( i % OUTPUT_REFRESH_RATE == 0 )); then
    NOW=$(date +%s)
    ELAPSED_TIME=$((NOW - RUN_START_TIME))
    ELAPSED_HOURS=$((ELAPSED_TIME / 3600))
    ELAPSED_MINUTES=$(((ELAPSED_TIME % 3600) / 60))
    ELAPSED_SECONDS=$((ELAPSED_TIME % 60))
    PRETTY_LOG_ELAPSED=$(printf "[%02d:%02d:%02d]" "$ELAPSED_HOURS" "$ELAPSED_MINUTES" "$ELAPSED_SECONDS")
  fi
}
update_elapsed_time 0

function file_update {
  local function_name="$1"
  local counter="$2"
  local total="$3"
  local name="$4"
  local base="$5"
  local file_path="$6"
  local file_destination="$7"
  if [[ "$IS_A_TTY" == "$FALSE" ]]; then 
    printf "(%s) %s [%d/%d] %s: %s | DEBUG: %s -> %s" "$function_name" "$PRETTY_LOG_ELAPSED" "$counter" "$total" "$name" "${base//%/%%}" "${file_path//%/%%}" "${file_destination//%/%%}"
  else
    if (( counter % OUTPUT_REFRESH_RATE == 0 )); then
      printf "\r\033[K%b%s [%d/%d] %s: %s%b" "$C_BLUE" "$PRETTY_LOG_ELAPSED"  "$counter" "$total" "$name" "${base//%/%%}" "$C_RESET"
    fi
  fi
}

# copy functions (the functions that actually do the heavy lifting)
function copy_files_flat {
  local name="$1"
  local dest="$2"
  shift 2
  local files=("$@")
  local total=${#files[@]}
  local counter=1
  local copied=0
  local warning="${C_YELLOW}"

  if [[ "$IS_A_TTY" == "$FALSE" ]]; then
    local TMP_FILES="${files[@]}"
    printf "(copy_files_flat) paths: %s\n" "${TMP_FILES}"
  fi

  for f in "${files[@]}"; do
    base=$(basename "$f")
    update_elapsed_time $counter
    file_update "copy_files_flat" "$counter" "$total" "$name" "${base}" "${f}" "${dest}"
    if [[ -e "$dest/$base" ]]; then
      if [[ "$IS_A_TTY" == "$FALSE" ]]; then
        printf "(copy_files_flat) %s WARNING duplicate %s skipped: %s" "$PRETTY_LOG_ELAPSED" "$name" "$base"
      else
        warning="$warning\n${PRETTY_LOG_ELAPSED} WARNING: duplicate $name skipped: $base"
      fi
    else
      if [[ "$IS_A_TTY" == "$FALSE" ]]; then
        cp -v "$f" "$dest"
      else
        cp "$f" "$dest"
      fi
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

  # header from first file: everything up to but not including the first (symbol line
  awk '/^[[:space:]]*\(symbol/{exit} {print}' "${files[0]}" > "$dest"

  if [[ "$IS_A_TTY" == "$FALSE" ]]; then
    local TMP_FILES="${files[@]}"
    printf "(copy_files_merge_symbols) paths: %s\n" "${TMP_FILES}"
  fi

  for f in "${files[@]}"; do
    printf "(copy_files_merge_symbols) merging file: %s into the symbol library\n" "${f}"
    # Extract complete symbol blocks preserving their structure
    # Track indentation properly to handle nested sub-symbols
    awk '
      BEGIN { in_symbol = 0; symbol_depth = 0 }
      
      /^[[:space:]]*\(kicad_symbol_lib/ { next }
      /^[[:space:]]*\)$/ && symbol_depth == 1 { 
        # Closing the top-level symbol
        print "  )"
        symbol_depth = 0
        in_symbol = 0
        next
      }
      
      /^[[:space:]]*\(symbol/ {
        match($0, /^[[:space:]]*/)
        current_indent = RLENGTH
        
        if (!in_symbol) {
          # First top-level symbol
          in_symbol = 1
          symbol_depth = 1
          base_indent = current_indent
          indent_unit = -1
          content = substr($0, current_indent + 1)
          print "  " content
        } else {
          # Nested sub-symbol - detect indent_unit if needed
          if (indent_unit < 0 && current_indent > base_indent) {
            indent_unit = current_indent - base_indent
            if (indent_unit < 1) indent_unit = 2
          }
          if (indent_unit < 0) indent_unit = 2
          
          # Calculate nesting level
          relative_indent = current_indent - base_indent
          nesting_level = int(relative_indent / indent_unit)
          new_indent = 2 + (nesting_level * 2)
          if (new_indent < 2) new_indent = 2
          
          content = substr($0, current_indent + 1)
          printf "%*s%s\n", new_indent, "", content
        }
        next
      }
      
      in_symbol {
        # Process non-symbol lines
        match($0, /^[[:space:]]*/)
        current_indent = RLENGTH
        
        # Detect indent_unit from first nested line if not set
        if (indent_unit < 0 && current_indent > base_indent) {
          indent_unit = current_indent - base_indent
          if (indent_unit < 1) indent_unit = 2
        }
        if (indent_unit < 0) indent_unit = 2
        
        # Calculate nesting level
        relative_indent = current_indent - base_indent
        nesting_level = int(relative_indent / indent_unit)
        new_indent = 2 + (nesting_level * 2)
        if (new_indent < 2) new_indent = 2
        
        content = substr($0, current_indent + 1)
        printf "%*s%s\n", new_indent, "", content
      }
    ' "$f" >> "$dest"
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

  if [[ "$IS_A_TTY" == "$FALSE" ]]; then
    local TMP_DIRS="${dirs[@]}"
    printf "(copy_3dshape_dirs) paths: %s\n" "${TMP_DIRS}"
  fi

  for d in "${dirs[@]}"; do
    update_elapsed_time $counter
    name="$(basename "$d")"
    file_update "copy_3dshape_dirs" "$counter" "$total" "3D model" "${name}" "${f}" "${dest}"
    if [[ -e "$dest/$name" ]]
    then
      if [[ "$IS_A_TTY" == "$FALSE" ]]; then
        printf "(copy_3dshape_dirs) %s WARNING duplicate 3D model skipped: %s" "$PRETTY_LOG_ELAPSED" "$base"
      else
        warning="$warning\n${PRETTY_LOG_ELAPSED} WARNING: duplicate 3D model skipped: $base"
      fi
    else
      if [[ "$IS_A_TTY" == "$FALSE" ]]; then
        cp -rv "$d" "$dest"
      else
        cp -r "$d" "$dest"
      fi
      ((copied++))
    fi
    ((counter++))
  done
  echo -e "$warning${C_RESET}"
  echo -e "${C_GREEN}$copied of $total 3D models copied${C_RESET}"
}

# Functions for handling troublemakers

function compile_troublemakers {
  local result=()
  local first=1
  local pattern_choice=${PATTERN_CHOICE_OVERRIDE:-3}
  local advanced=${ADVANCED_CHOICE_OVERRIDE:-$TRUE}

  if [[ "$advanced" == "$TRUE" ]]; then
    for excl in "$@"; do
      if [[ "$pattern_choice" == "1" ]];then
        result+=( -not -path "$excl" ) # exclude the directory
      elif [[ "$pattern_choice" == "2" ]]; then
        result+=( -not -ipath "$excl" ) # case insensitive
      elif [[ "$pattern_choice" == "3" ]]; then
        result+=( -not -path "*/$excl/*" ) # exclude by path
      elif [[ "$pattern_choice" == "4" ]]; then
        result+=( -not -ipath "*/$excl/*" ) # case insensitive
      elif [[ "$pattern_choice" == "5" ]]; then
        result+=( -not -path "$SRC_DIR/$excl" ) # corrected
      elif [[ "$pattern_choice" == "6" ]]; then
        result+=( -not -ipath "$SRC_DIR/$excl" ) # corrected
      elif [[ "$pattern_choice" == "7" ]]; then
        result+=( -not -name "$excl" -not -path "*/$excl/*" ) # combined
      elif [[ "$pattern_choice" == "8" ]]; then
        result+=( -not -iname "$excl" -not -ipath "*/$excl/*" ) # combined
      elif [[ "$pattern_choice" == "9" ]]; then
        result+=( -not -name "$excl" -not -path "$SRC_DIR/$excl" ) # combined
      elif [[ "$pattern_choice" == "10" ]]; then
        result+=( -not -iname "$excl" -not -ipath "$SRC_DIR/$excl" ) # combined
      elif [[ "$pattern_choice" == "11" ]]; then
        result+=( -not -path "$excl" -not -path "$SRC_DIR/$excl/*" ) # directory and contents
      else
        result+=( -not -ipath "$excl" -not -ipath "$SRC_DIR/$excl/*" ) # directory and contents
      fi
    done
  else
    for excl in "$@"; do
      result+=( -not -path "*/$excl/*" )
    done
  fi

  # Return the array by printing, but capture with array assignment
  printf "%s\n" "${result[@]}"
}




function check_that_no_troublemakers_have_slipped_in {
  local hit
  local pattern_args=()

  # Dynamically build find arguments from EXCLUDE_PATHS
  for excl in "${EXCLUDE_PATHS[@]}"; do
    pattern_args+=( -iname "$excl" -o )
  done
  unset 'pattern_args[${#pattern_args[@]}-1]'  # remove trailing -o

  hit=$(find "$BUILD_DIR" -type d \( "${pattern_args[@]}" \) -print -quit)

  if [[ -n "$hit" ]]; then
    echo -e "${C_RED}ERROR: gated content leaked into public build:${C_RESET}"
    echo "  $hit"
    exit 1
  fi
}

function handle_troublemakers {
  local type="$1"       # "footprint" / "symbol" / "3D"
  local src_dir="$2"    # src root
  local out_dir="$3"    # build root for this type
  shift 3
  local providers=("$@") # EXCLUDE_PATHS

  if [[ "$IS_A_TTY" == "$FALSE" ]]; then
    printf "(handle_troublemakers) type: %s, src_dir: %s, out_dir: %s, providers: %s" "${type}" "${src_dir}" "${out_dir}" "${providers}"
  fi

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
        mapfile -t files < <(find "$src_dir" -path "*/$provider/*" -type f -name "*.kicad_sym" | sort)
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

mapfile -t PRUNE_DIRS < <(compile_troublemakers "${EXCLUDE_PATHS[@]}")
if [[ "$IS_A_TTY" == "$FALSE" ]]; then
  printf "(boot up) PRUNE_DIRS = %s\n" "${PRUNE_DIRS[@]}"
fi

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
mapfile -t footprint_files < <(find "$SRC_DIR" "${PRUNE_DIRS[@]}" -name "*.kicad_mod" | sort)
if [[ "$IS_A_TTY" == "$FALSE" ]]; then
  printf "(Footprints) footprint_files = %s\n" "${footprint_files[@]}"
fi
num_fp=${#footprint_files[@]}
echo -e "${C_GREEN}Found $num_fp footprints.${C_RESET}"

copy_files_flat "Footprint" "$FP_DIR" "${footprint_files[@]}"
echo -e "\n${C_GREEN}Footprints done.${C_RESET}"

#######################################
# Symbols (merged)
#######################################
echo ""
echo -e "${C_CYAN}Collecting symbol files (.kicad_sym)...${C_RESET}"
mapfile -t symbol_files < <(find "$SRC_DIR"  "${PRUNE_DIRS[@]}" -name "*.kicad_sym" | sort)
if [[ "$IS_A_TTY" == "$FALSE" ]]; then
  printf "(Symbols) symbol_files = %s\n" "${symbol_files[@]}"
fi
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
  find "$SRC_DIR" "${PRUNE_DIRS[@]}" -type d -name "*.3dshapes" | sort
)
if [[ "$IS_A_TTY" == "$FALSE" ]]; then
  printf "(3D models) model_dirs = %s\n" "${model_dirs[@]}"
fi
num_models=${#model_dirs[@]}
echo -e "${C_GREEN}Found $num_models model files.${C_RESET}"

copy_3dshape_dirs "$MODEL_DIR" "${model_dirs[@]}"

echo -e "\n${C_GREEN}3D models done.${C_RESET}"

#####################################
# Checking that no troublemakers slipped in
#####################################
check_that_no_troublemakers_have_slipped_in

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

#####################################
# Timer tracking - end + report
#####################################
update_elapsed_time 0

printf "Execution time: %02dh %02dm %02ds\n" "$ELAPSED_HOURS" "$ELAPSED_MINUTES" "$ELAPSED_SECONDS"
