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
# FILE: colours.py
# CREATION DATE: 19-02-2026
# LAST Modified: 3:4:14 02-03-2026
# DESCRIPTION:
# This is a program that allows you to combine all the KiCad libraries into a single instance.
# This would make importing easier, less files to add to the KiCad import list.
# /STOP
# COPYRIGHT: (c) Henry Letellier
# PURPOSE: This is the file in charge of storing the different colours used in the program.
# // AR
# +==== END KiCad combiner =================+
"""

from .global_constants import IS_A_TTY


class Colours:
    """
        Class in charge of storing the colour instances used in the program
    """
    _instance = None
    C_BACKGROUND = ""
    C_RED = ""
    C_PINK = ""
    C_CYAN = ""
    C_BLUE = ""
    C_WHITE = ""
    C_GREEN = ""
    C_RESET = ""
    C_YELLOW = ""

    def __new__(cls, *args, **kwargs) -> "Colours":
        """Ensure only one instance exists."""
        if cls._instance is None:
            cls._instance = super().__new__(cls)
            if IS_A_TTY:
                cls.C_BACKGROUND = "\033[48;5;16m"
                cls.C_RED = f"\033[38;5;9m${cls.C_BACKGROUND}"
                cls.C_PINK = f"\033[38;5;206m${cls.C_BACKGROUND}"
                cls.C_CYAN = f"\033[38;5;87m${cls.C_BACKGROUND}"
                cls.C_BLUE = f"\033[38;5;45m${cls.C_BACKGROUND}"
                cls.C_WHITE = f"\033[38;5;15m${cls.C_BACKGROUND}"
                cls.C_GREEN = f"\033[38;5;46m${cls.C_BACKGROUND}"
                cls.C_RESET = f"\033[0m${cls.C_BACKGROUND}"
                cls.C_YELLOW = f"\033[38;5;226m${cls.C_BACKGROUND}"
        return cls._instance
