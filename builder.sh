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
for file in "${footprint_files[@]}"; do
  echo "Copying footprint $counter of $num_mod: $(basename "$file")"
  cp "$file" build/footprints/Misc.pretty/
  ((counter++))
done

echo "Merging symbol libraries (.kicad_sym) into build/symbols.kicad_sym..."
# Find and count symbol files
mapfile -t symbol_files < <(find src -name "*.kicad_sym")
num_sym=${#symbol_files[@]}
echo "Found $num_sym symbol files to merge."
# Merge all .kicad_sym files into one
output_sym="build/symbols.kicad_sym"
echo "(kicad_symbol_lib" > "$output_sym"
echo "	(version 20241209)" >> "$output_sym"
echo "	(generator \"kicad_symbol_editor\")" >> "$output_sym"
echo "	(generator_version \"9.0\")" >> "$output_sym"
find src -name "*.kicad_sym" -exec sed '1,4d; $d; $d' {} \; >> "$output_sym"
echo ")" >> "$output_sym"
echo ")" >> "$output_sym"
echo "Merged $num_sym symbol files."

echo "Build process completed successfully."
