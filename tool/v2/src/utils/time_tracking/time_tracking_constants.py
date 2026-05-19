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
# FILE: time_tracking_constants.py
# CREATION DATE: 01-03-2026
# LAST Modified: 22:35:55 01-03-2026
# DESCRIPTION:
# This is a program that allows you to combine all the KiCad libraries into a single instance.
# This would make importing easier, less files to add to the KiCad import list.
# /STOP
# COPYRIGHT: (c) Henry Letellier
# PURPOSE: This is the file that will store the constants of the time tracking module.
# // AR
# +==== END KiCad combiner =================+
"""

from enum import Enum
from typing import Optional
from datetime import datetime, timedelta
from dataclasses import dataclass


@dataclass
class TimeBreakdown:
    hours: int = 0
    minutes: int = 0
    seconds: int = 0


class TimerStatus(Enum):
    NO_EXISTS = 0
    CREATED = 1
    EXISTS = 2
    RUNNING = 3
    STOPPED = 4


@dataclass
class TimerRecord:
    name: str
    start_time: datetime
    end_time: Optional[datetime] = None
    total_runtime: Optional[timedelta] = None
    status: TimerStatus = TimerStatus.NO_EXISTS
