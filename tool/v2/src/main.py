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
# FILE: main.py
# CREATION DATE: 16-02-2026
# LAST Modified: 18:5:17 06-03-2026
# DESCRIPTION:
# This is a program that allows you to combine all the KiCad libraries into a single instance.
# This would make importing easier, less files to add to the KiCad import list.
# /STOP
# COPYRIGHT: (c) Henry Letellier
# PURPOSE: This is the main file of the program (the one that is used by the __main__.py and __init__.py files)
# // AR
# +==== END KiCad combiner =================+
"""

import os
import sys
from sys import argv
from typing import Any, List
from pathlib import Path

from display_tty import Disp, initialise_logger
from rotary_logger import RotaryLogger, RL_CONST
from tty_ov import TTY, ColouriseOutput, AskQuestion

try:
    from .utils import CONST
except ImportError:
    print("Failed to import dependencies from the relative path, trying direct import")
    try:
        from utils import CONST
        print("Import success")
    except ImportError as f:
        raise RuntimeError(
            "Failed to import required dependencies for the program."
        ) from f


# class Main:
#     """ The main class of the program """

#     def __init__(self, colourise_output: bool = True) -> None:
#         super().__init__()
#         self.err = CONST.ERR
#         self.error = CONST.ERROR
#         self.success = CONST.SUCCESS
#         self.colours = CONST.COLOURS
#         # finish the imports
#         self.co = ColouriseOutput()
#         self.aq = AskQuestion()
#         self.tty = TTY(
#             self.err,
#             self.error,
#             self.success,
#             self.co,
#             self.aq,
#             CONST.COLOURS,
#             colourise_output
#         )
#         self.tty.load_basics()
#         self.docker = Docker(self.success, self.err, self.error, self.tty)
#         self.docker_compose = DockerCompose(
#             self.success,
#             self.err,
#             self.error,
#             self.tty
#         )
#         self.kubernetes = Kubernetes(
#             self.success,
#             self.err,
#             self.error,
#             self.tty
#         )

#     def call_injectors(self) -> None:
#         """ The function in charge of calling the injectors of the classes """
#         status = self.docker.injector()
#         if status != self.success:
#             self.tty.print_on_tty(
#                 self.tty.error_colour,
#                 "Error while injecting tty with the Docker class\n"
#             )
#         status = self.docker_compose.injector()
#         if status != self.success:
#             self.tty.print_on_tty(
#                 self.tty.error_colour,
#                 "Error while injecting tty with the Docker Compose class\n"
#             )
#         status = self.kubernetes.injector()
#         if status != self.success:
#             self.tty.print_on_tty(
#                 self.tty.error_colour,
#                 "Error while injecting tty with the Kubernetes class\n"
#             )

#     def compile_characters(self, char: str = " ", nb: int = 5) -> str:
#         """ Compile a string of characters """
#         string = ""
#         index = 0
#         while index < nb:
#             string += char
#             index += 1
#         return string

#     def add_spacing(self) -> None:
#         """ Add some spacing between the loading function and the title """
#         spacing = self.compile_characters("\n", 2)
#         self.tty.print_on_tty(
#             self.tty.default_colour,
#             spacing
#         )

#     def run_command(self, args: list) -> int:
#         """ Run a command in parent langage """
#         help_command = "run"
#         if self.tty.help_function_child_name == help_command:
#             help_description = f"""
# This is a command that allows you to run a command on the parent shell.
# Input:
#     {help_command} <your command>
# Output:
#     The result of the command you ran.
# Example:
# Input:
#     {help_command} echo "Hello World"
# Output:
#     Hello World
# """
#             self.tty.function_help(help_command, help_description)
#             self.tty.current_tty_status = self.success
#             return self.success
#         if len(args) < 1:
#             self.tty.print_on_tty(
#                 self.tty.error_colour,
#                 "You need to specify a command to run\n"
#             )
#             self.tty.current_tty_status = self.error
#             return self.error
#         command = " ".join(args)
#         self.tty.print_on_tty(
#             self.tty.default_colour,
#             f"Running command: {command}\n"
#         )
#         status = self.tty.run_external_command(command)
#         if status != self.success:
#             self.tty.print_on_tty(
#                 self.tty.error_colour,
#                 "Error while running command\n"
#             )
#             self.tty.current_tty_status = self.error
#             return self.error
#         self.tty.current_tty_status = self.success
#         return self.success

#     def main(self) -> None:
#         """ The main function of the program """
#         self.call_injectors()
#         self.add_spacing()
#         status = self.tty.mainloop()
#         self.tty.unload_basics()
#         print()
#         sys.exit(status)


class Main:

    disp: Disp = initialise_logger(__qualname__, False)

    def __init__(self, debug: bool = False) -> None:
        self.src_dir = "src"
        self.build_dir = "build"
        # Output destinations
        self.fp_dir: Path = Path(f"{self.build_dir}") / \
            "footprints"/"Misc.pretty"
        self.sym_dir: Path = Path(f"{self.build_dir}")/"symbols"
        self.sym_out: Path = Path(f"{self.sym_dir}")/"Combined.kicad_sym"
        self.model_dir: Path = Path(f"{self.build_dir}")/"3dmodels"
        self.model_var: Path = Path("MY_3DMODELS")
        # Troublemakers (for IP reasons)
        self.exclude_paths: List[Path] = [Path("ultra_librarian")]
        self.success: int = 0
        self.error: int = 1
        # Colour settings
        self.colourise_output = True
        # Debug mode
        self.debug = debug
        # finish the imports
        self.co = ColouriseOutput()
        self.aq = AskQuestion()
        self.tty = TTY(
            self.error,
            self.error,
            self.success,
            self.co,
            self.aq,
            CONST.COLOURS,
            self.colourise_output
        )

    def __call__(self, *args: Any, **kwds: Any) -> int:
        return self.main()

    def _check_args(self) -> None:
        for arg in sys.argv[1:]:
            arg_low = arg.lower()
            if arg_low in CONST.ARG_NO_COLOUR:
                self.colourise_output = False
                continue
            if arg_low in CONST.ARG_DEBUG:
                self.debug = True
                continue
            self.disp.log_error(f"Argument: {arg} not recognised")
            continue

    def _bootstraper(self) -> None:
        self.tty.load_basics()

    def _start(self) -> int:
        return self.tty.mainloop()

    def _shutdown(self) -> int:
        return self.tty.unload_basics()

    def main(self) -> int:
        print(f"argv={argv}, argc={len(argv)}")
        self._check_args()
        self._bootstraper()
        status = self._start()
        status2 = self._shutdown()
        if status != self.success:
            self.disp.log_error(
                f"The terminal exited with an error status of {status}"
            )
            return status
        if status2 != self.success:
            self.disp.log_error(
                f"The terminal exited without any errors but the cleanup exited with status: {status2}"
            )
            return status2
        return self.success


def entrypoint(debug: bool = False) -> int:
    log_path: Path = Path(__file__).parent
    if log_path.name == "src":
        log_path = log_path.parent
    merge_streams: bool = os.environ.get(
        "MERGE_STREAMS",
        "true"
    ).lower() in CONST.TRUE_ENV
    log_stdin: bool = os.environ.get(
        "LOG_STDIN", "true"
    ).lower() in CONST.TRUE_ENV
    merge_stdin: bool = os.environ.get(
        "MERGE_STDIN", "false"
    ).lower() in CONST.TRUE_ENV
    instance = RotaryLogger(
        merge_streams=merge_streams,
        log_to_file=RL_CONST.LOG_TO_FILE_ENV,
        raw_log_folder=str(log_path),
        default_log_folder=log_path,
        capture_stdin=log_stdin,
        merge_stdin=merge_stdin
    )
    instance.start_logging()
    status = Main(debug)()
    instance.stop_logging()
    return status


if __name__ == "__main__":
    STATUS = entrypoint()
    print(f"Exit status: {STATUS}")
    sys.exit(STATUS)
