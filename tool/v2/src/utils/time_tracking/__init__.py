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
# CREATION DATE: 01-03-2026
# LAST Modified: 0:7:33 02-03-2026
# DESCRIPTION:
# This is a program that allows you to combine all the KiCad libraries into a single instance.
# This would make importing easier, less files to add to the KiCad import list.
# /STOP
# COPYRIGHT: (c) Henry Letellier
# PURPOSE: This is the file that allows the module to have it's components imported without a hitch.
# // AR
# +==== END KiCad combiner =================+
"""

from .time_tracking import TimeTracking
from . import time_tracking_constants as TIME_CONSTS

__all__ = [
    "TimeTracking",
    "TIME_CONSTS"
]
