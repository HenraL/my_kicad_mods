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
# FILE: global_constants.py
# CREATION DATE: 19-02-2026
# LAST Modified: 15:44:45 06-03-2026
# DESCRIPTION:
# This is a program that allows you to combine all the KiCad libraries into a single instance.
# This would make importing easier, less files to add to the KiCad import list.
# /STOP
# COPYRIGHT: (c) Henry Letellier
# PURPOSE: These are the constants that will be used globally throughout the program.
# // AR
# +==== END KiCad combiner =================+
"""

import sys
from typing import Tuple

# Human boolean rebind.
YES = True
NO = False

# Are we in a terminal ?
IS_A_TTY = sys.stdout.isatty()

# status codes
ERR = 1
ERROR = ERR
SUCCESS = 0

# TTY colour options
COLOURS = {
    "default": "0A",
    "prompt": "0B",
    "error": "0C",
    "success": "03",
    "info": "0D",
    "reset": "rr",
    "help_title_colour": "0E",
    "help_command_colour": "0A",
    "help_description_colour": "0F",
    "env_term_colour": "09",
    "env_shell_colour": "03",
    "env_definition_colour": "0B",
    "session_name_colour": "0D"
}

# Arguments

ARG_NO_COLOUR = ('-nc', '/nc', '--no-colour', '/no-colour')
ARG_DEBUG = ("-d", "--debug", "/d", "/debug")

# True/False env
TRUE_ENV: Tuple[str, ...] = ("1", "true", "yes")
FALSE_ENV: Tuple[str, ...] = ("0", "false", "no")
