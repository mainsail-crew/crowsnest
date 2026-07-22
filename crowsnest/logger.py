#### crowsnest - A webcam Service for multiple Cams and Stream Services.
####
#### Written by Patrick Gehrsitz aka mryel00 <mryel00.github@gmail.com>
#### Copyright 2025 - till today
#### https://github.com/mainsail-crew/crowsnest
####
#### This File is distributed under GPLv3
####

import functools
import logging
import logging.handlers
import os
import sys
from typing import Protocol

DEV = 10
DEBUG = 15
QUIET = 35

indentation = 6 * " "

logger = logging.getLogger("crowsnest")


class LogFunc(Protocol):
    def __call__(self, msg: str, prefix: str = "", **kwargs) -> None: ...


def setup_logging(
    log_path: str, filemode: str = "a", log_level: int = logging.INFO
) -> None:
    # Create log directory if it does not exist.
    os.makedirs(os.path.dirname(log_path), exist_ok=True)

    logging.addLevelName(DEV, "DEV")
    logging.addLevelName(DEBUG, "DEBUG")
    logging.addLevelName(QUIET, "QUIET")

    logger.propagate = False
    formatter = logging.Formatter(
        "[%(asctime)s] %(message)s", datefmt="%d/%m/%y %H:%M:%S"
    )

    filehandler = logging.handlers.RotatingFileHandler(
        log_path,
        mode=filemode,
        encoding="utf-8",
        maxBytes=3 * 1024 * 1024,
        backupCount=5,
    )
    filehandler.setFormatter(formatter)
    logger.addHandler(filehandler)

    # StreamHandler for stdout.
    streamhandler = logging.StreamHandler(sys.stdout)
    streamhandler.setFormatter(formatter)
    logger.addHandler(streamhandler)

    # Set log level.
    logger.setLevel(log_level)


def set_log_level(level: int) -> None:
    logger.setLevel(level)


def log(level: int, msg: str, prefix: str = "", **kwargs) -> None:
    level_prefix = kwargs.pop("level_prefix", "")
    if level_prefix:
        final_msg = f"{level_prefix}: {prefix}{msg}"
    else:
        final_msg = f"{prefix}{msg}"
    logger.log(level, final_msg, **kwargs)


log_quiet: LogFunc = functools.partial(log, QUIET)
log_info: LogFunc = functools.partial(log, logging.INFO, level_prefix="INFO")
log_info_silent: LogFunc = functools.partial(log, logging.INFO)
log_debug: LogFunc = functools.partial(log, DEBUG, level_prefix="DEBUG")
log_warning: LogFunc = functools.partial(log, logging.WARNING, level_prefix="WARN")
log_error: LogFunc = functools.partial(log, logging.ERROR, level_prefix="ERROR")


def log_multiline(msg: str, log_func: LogFunc, *args, **kwargs) -> None:
    lines = msg.split("\n")
    line_prefix = kwargs.pop("line_prefix", "")
    for line in lines:
        if line_prefix:
            final_line = f"{line_prefix}: {line}"
        else:
            final_line = f"{line}"
        log_func(final_line, *args, **kwargs)
