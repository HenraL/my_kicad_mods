#!/usr/bin/env bash
set -e

rm -rf build
mkdir -p build/footprints build/symbols build/3dmodels

find src -name "*.kicad_mod" \
  -exec cp {} build/footprints/Misc.pretty/ \;

find src -name "*.kicad_sym" \
  -exec cp {} build/symbols/ \;
