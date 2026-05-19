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
# CREATION DATE: 19-02-2026
# LAST Modified: 0:8:47 02-03-2026
# DESCRIPTION:
# This is a program that allows you to combine all the KiCad libraries into a single instance.
# This would make importing easier, less files to add to the KiCad import list.
# /STOP
# COPYRIGHT: (c) Henry Letellier
# PURPOSE: This is the file that allows an easy import of the code located in the utils folder.
# // AR
# +==== END KiCad combiner =================+
"""

from .time_tracking import TimeTracking, TIME_CONSTS
from .colours import Colours
from . import global_constants as CONST

__all__ = [
    "TimeTracking",
    "TIME_CONSTS",
    "Colours",
    "CONST"
]
