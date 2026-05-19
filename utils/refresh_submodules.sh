#!/bin/bash
# 
# +==== BEGIN KiCad combiner =================+
# LOGO:
# .................................
# .+-------+..+-------+..+-------+.
# .|.LIB.A.|..|.LIB.B.|..|.LIB.C.|.
# .+-------+..+-------+..+-------+.
# ....|...........|..........|.....
# ....+-----------+----------+.....
# ................|................
# .........+--------------+........
# .........|.LIB.Combined.|........
# .........+--------------+........
# .................................
# /STOP
# PROJECT: KiCad combiner
# FILE: refresh_submodules.sh
# CREATION DATE: 19-05-2026
# LAST Modified: 14:54:18 19-05-2026
# DESCRIPTION:
# This is a program that allows you to combine all the KiCad libraries into a single instance.
# This would make importing easier, less files to add to the KiCad import list.
# /STOP
# COPYRIGHT: (c) Henry Letellier
# PURPOSE: This is the file in charge of refreshing the submodules containing the kicad symbols that can then be imported into kicad.
# // AR
# +==== END KiCad combiner =================+
# 

# Update all submodules to their latest version
echo "Updating submodules to their latest versions..."
git submodule update --remote

# Check if the submodule update succeeded
if [ $? -eq 0 ]; then
    echo "Submodules updated successfully."
else
    echo "Warning: Some submodules could not be updated (they may not be accessible to you)."
fi

# Call builder.sh
echo "Running builder.sh..."
./builder.sh
