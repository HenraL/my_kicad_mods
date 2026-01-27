#!/usr/bin/env bash
set -e

echo "Starting KiCad mods build process..."

echo "Cleaning up previous build directory..."
rm -rf build

echo "Creating build directories..."
mkdir -p build/footprints/Misc.pretty build/symbols build/3dmodels

echo "Copying footprint files (.kicad_mod) to build/footprints/Misc.pretty/..."
# Find and count footprint files
mapfile -t footprint_files < <(find src -name "*.kicad_mod")
num_mod=${#footprint_files[@]}
echo "Found $num_mod footprint files to copy."
counter=1
FILE_NAME=""
for file in "${footprint_files[@]}"; do
  FILE_NAME=$(basename "$file" | tr -d '\n')
  printf '\r\033[KCopying footprint %d of %d: %s' "$counter" "$num_mod" "$FILE_NAME"
  cp "$file" build/footprints/Misc.pretty/
  ((counter++))
done
echo ""  # New line after progress
echo "Copied $num_mod footprint files."

echo "Copying 3D model files to build/3dmodels/..."
# Find and count 3D model files
mapfile -t model_files < <(find src -type f \( -name "*.wrl" -o -name "*.step" -o -name "*.stp" \))
num_models=${#model_files[@]}
echo "Found $num_models 3D model files to copy."
counter=1
for file in "${model_files[@]}"; do
  FILE_NAME=$(basename "$file" | tr -d '\n')
  printf '\r\033[KCopying 3D model %d of %d: %s' "$counter" "$num_models" "$FILE_NAME"
  cp "$file" build/3dmodels/
  ((counter++))
done
echo ""  # New line after progress
echo "Copied $num_models 3D model files."

echo "Copying symbol files (.kicad_sym) to build/symbols/..."
# Find and count symbol files
mapfile -t symbol_files < <(find src -name "*.kicad_sym")
num_sym=${#symbol_files[@]}
echo "Found $num_sym symbol files to copy."
counter=1
for file in "${symbol_files[@]}"; do
  FILE_NAME=$(basename "$file" | tr -d '\n')
  printf '\r\033[KCopying symbol %d of %d: %s' "$counter" "$num_sym" "$FILE_NAME"
  cp "$file" build/symbols/
  ((counter++))
done
echo ""  # New line after progress
echo "Copied $num_sym symbol files."

echo "Build process completed successfully."
