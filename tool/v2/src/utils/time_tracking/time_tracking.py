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
# FILE: time_tracking.py
# CREATION DATE: 01-03-2026
# LAST Modified: 0:7:44 02-03-2026
# DESCRIPTION:
# This is a program that allows you to combine all the KiCad libraries into a single instance.
# This would make importing easier, less files to add to the KiCad import list.
# /STOP
# COPYRIGHT: (c) Henry Letellier
# PURPOSE: This is the file in charge of tracking the time required for the program to run.
# // AR
# +==== END KiCad combiner =================+
"""

from enum import Enum
from datetime import datetime, timedelta
from typing import Dict, Optional, Union


from display_tty import Disp, initialise_logger

from . import time_tracking_constants as TIME_CONSTS


class TimeTracking:
    """Singleton tracker supporting multiple named timers.

    Timers may be addressed by a string or an Enum member.
    The user-facing identifier is converted to a stable string key internally.
    If a timer does not exist when stopped, a record is created and stopped immediately.
    """

    _instance: Optional["TimeTracking"] = None
    _disp: Disp = initialise_logger(__qualname__, False)

    def __new__(cls, *args, **kwargs) -> "TimeTracking":
        """Ensure a single `TimeTracking` instance (singleton).

        Returns:
            TimeTracking: The singleton instance.
        """
        if cls._instance is None:
            cls._instance = super().__new__(cls)
        return cls._instance

    def __init__(self, opening: str = "[", hour: str = ":", minute: str = ":", seconds: str = "", closing: str = "]", debug: bool = False) -> None:
        """Initialize the `TimeTracking` singleton.

        Args:
            opening (str, optional): Opening string for `pretty_log`. Defaults to "[".
            hour (str, optional): Hour separator. Defaults to ":".
            minute (str, optional): Minute separator. Defaults to ":".
            seconds (str, optional): Seconds separator. Defaults to "".
            closing (str, optional): Closing string for `pretty_log`. Defaults to "]".
            debug (bool, optional): Enable debug logging. Defaults to False.
        """
        self._timers: Dict[str, TIME_CONSTS.TimerRecord] = {}
        self.default_timer_name: str = "default"
        self.opening = opening
        self.hour = hour
        self.minute = minute
        self.seconds = seconds
        self.closing = closing
        self.debug = debug
        self._disp.update_disp_debug(debug)

    def _determine_timer_name(self, timer_name: Optional[Union[str, Enum]]) -> str:
        """Convert a user-supplied timer identifier into an internal key.

        Args:
            timer_name (Optional[Union[str, Enum]]): User supplied timer name.

        Returns:
            str: Stable internal key used to index `self._timers`.
        """
        if timer_name is None:
            return self.default_timer_name
        if isinstance(timer_name, Enum):
            return f"{timer_name.__class__.__name__}.{timer_name.name}"
        return str(timer_name)

    def create(self, timer_name: Optional[Union[str, Enum]], stopped: bool = False) -> TIME_CONSTS.TimerStatus:
        """Create a timer only if it does not yet exist

        Args:
            timer_name (Optional[Union[str, Enum]]): The name of the time

        Returns:
            TimerStatus: _description_
        """
        _timer_name = self._determine_timer_name(timer_name)
        if _timer_name in self._timers:
            return TIME_CONSTS.TimerStatus.EXISTS
        _now = datetime.now()
        if stopped is False:
            self._timers[_timer_name] = TIME_CONSTS.TimerRecord(
                name=_timer_name,
                start_time=_now,
                status=TIME_CONSTS.TimerStatus.RUNNING
            )
        else:
            self._timers[_timer_name] = TIME_CONSTS.TimerRecord(
                name=_timer_name,
                start_time=_now,
                status=TIME_CONSTS.TimerStatus.STOPPED,
                end_time=_now,
                total_runtime=_now - _now
            )
        return TIME_CONSTS.TimerStatus.CREATED

    def start(self, timer_name: Optional[Union[str, Enum]] = None) -> TIME_CONSTS.TimerStatus:
        """Start or restart a timer_name timer. Returns internal timer_name key.

        Args:
            timer_name (Optional[Union[str, Enum]], optional): The timer to work on. Defaults to None.

        Returns:
            TIME_CONSTS.TimerStatus: The status of the function.
        """
        _timer_name = self._determine_timer_name(timer_name)
        status = self.create(_timer_name, stopped=False)
        if status == TIME_CONSTS.TimerStatus.CREATED:
            return TIME_CONSTS.TimerStatus.RUNNING
        self.reset(_timer_name, stopped=False)
        return TIME_CONSTS.TimerStatus.RUNNING

    def stop(self, timer_name: Optional[Union[str, Enum]] = None) -> None:
        """Stop a timer_name timer; if timer_name doesn't exist create+stop it immediately.

        Args:
            timer_name (Optional[Union[str, Enum]], optional): the name of the timer to work on. Defaults to None.
        """
        key = self._determine_timer_name(timer_name)
        now = datetime.now()
        timer_instance = self._timers.get(key)
        if timer_instance is None:
            # initialize then stop immediately
            if timer_name is None:
                name_val = "default"
            else:
                name_val = str(timer_name)
            self._timers[key] = TIME_CONSTS.TimerRecord(
                name=name_val,
                start_time=now,
                end_time=now,
                total_runtime=timedelta(0)
            )
            return
        timer_instance.end_time = now
        timer_instance.total_runtime = timer_instance.end_time - timer_instance.start_time

    def _ensure_total(self, timer_instance: TIME_CONSTS.TimerRecord) -> None:
        """Ensure `total_runtime` is set on a `TimerRecord`.

        If `total_runtime` is None, set `end_time` to now (if missing)
        and compute `total_runtime` as `end_time - start_time`.

        Args:
            timer_instance (TIME_CONSTS.TimerRecord): The timer record to update.
        """
        if timer_instance.total_runtime is None:
            if timer_instance.end_time is None:
                timer_instance.end_time = datetime.now()
            timer_instance.total_runtime = timer_instance.end_time - timer_instance.start_time

    def _breakdown(self, td: timedelta) -> TIME_CONSTS.TimeBreakdown:
        """Convert a `timedelta` into a `TimeBreakdown` (hours/minutes/seconds).

        Args:
            td (timedelta): The elapsed time.

        Returns:
            TIME_CONSTS.TimeBreakdown: Dataclass with hours, minutes, seconds.
        """
        final = TIME_CONSTS.TimeBreakdown()
        seconds = int(td.total_seconds())
        final.hours = seconds // 3600
        final.minutes = (seconds % 3600) // 60
        final.seconds = seconds % 60
        return final

    def pretty_log(self, timer_name: Optional[Union[str, Enum]] = None, *, opening: Optional[str] = None, hour: Optional[str] = None, minute: Optional[str] = None, seconds: Optional[str] = None, closing: Optional[str] = None) -> str:
        """Return a beautified string of the beautified time so that it can be displayed

        Args:
            timer_name (Optional[Union[str, Enum]], optional): The name of the timer to process. Defaults to None.
            opening (Optional[str], optional): The opening character of the string. Defaults to None.
            hour (Optional[str], optional): The character separating the hours from the minutes. Defaults to None.
            minute (Optional[str], optional): The character separating the minutes from the seconds. Defaults to None.
            seconds (Optional[str], optional): The character separating the seconds from the closing character. Defaults to None.
            closing (Optional[str], optional): The closing character. Defaults to None.

        Returns:
            str: The formated string.
        """
        if opening is None:
            opening = self.opening
        if hour is None:
            hour = self.hour
        if minute is None:
            minute = self.minute
        if seconds is None:
            seconds = self.seconds
        if closing is None:
            closing = self.closing

        key = self._determine_timer_name(timer_name)
        timer_instance = self._timers.get(key)
        if timer_instance is None:
            return f"{opening}00{hour}00{minute}00{seconds}{closing}"

        self._ensure_total(timer_instance)
        assert timer_instance.total_runtime is not None
        timer_breakdown = self._breakdown(timer_instance.total_runtime)
        final = f"{opening}"
        final += f"{timer_breakdown.hours:02d}{hour}"
        final += f"{timer_breakdown.minutes:02d}{minute}"
        final += f"{timer_breakdown.seconds:02d}{seconds}"
        final += f"{closing}"
        return final

    def timer_names(self) -> Dict[str, TIME_CONSTS.TimerRecord]:
        """Return a pointer to all the timers currently stored in the class.

        Returns:
            Dict[str, TIME_CONSTS.TimerRecord]: The pointer to the instances.
        """
        return dict(self._timers)

    def _reset_single_node(self, timer_name: Optional[Union[str, Enum]] = None, stopped: bool = False) -> None:
        """Reset a single timer instance if present.

        Args:
            timer_name (Optional[Union[str, Enum]], optional): The timer to reset. Defaults to None.
            stopped (bool, optional): Wether to reset it and instantly stop it. Defaults to False.
        """
        _timer_name_str: str = self._determine_timer_name(timer_name)
        if _timer_name_str in self._timers:
            _now = datetime.now()
            _node = self._timers[_timer_name_str]
            _node.start_time = _now
            if stopped is True:
                _node.end_time = _now
                _node.status = TIME_CONSTS.TimerStatus.STOPPED
                _node.total_runtime = _now - _now
            else:
                _node.end_time = None
                _node.status = TIME_CONSTS.TimerStatus.RUNNING
                _node.total_runtime = None
        else:
            self.create(_timer_name_str, stopped)

    def reset(self, timer_name: Optional[Union[str, Enum]] = None, stopped: bool = False) -> None:
        """Reset a specific timer.

        Args:
            timer_name (Optional[Union[str, Enum]], optional): The timer to reset, if None, resets all the timers. Defaults to None.
            stopped (bool, optional): Wether to immediately stop the timer once it is reset. Defaults to False.
        """
        if timer_name is None:
            self._disp.log_warning(
                "A full reset has been called, all timers have thus been reset"
            )
            for key in self._timers:
                self._disp.log_debug(f"Resetting timer for timer_name: {key}")
                self._reset_single_node(key, stopped)
            return None
        self._reset_single_node(timer_name, stopped)
        return None
