""" 
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
# FILE: __init__.py
# CREATION DATE: 16-02-2026
# LAST Modified: 0:23:27 02-03-2026
# DESCRIPTION:
# This is a program that allows you to combine all the KiCad libraries into a single instance.
# This would make importing easier, less files to add to the KiCad import list.
# /STOP
# COPYRIGHT: (c) Henry Letellier
# PURPOSE: This is the file python calls when the it is imported as a library.
# // AR
# +==== END KiCad combiner =================+
"""


from .src import entrypoint, Main, CONST, TimeTracking

__all__ = [
    "Main",
    "entrypoint",
    "CONST",
    "TimeTracking"
]
