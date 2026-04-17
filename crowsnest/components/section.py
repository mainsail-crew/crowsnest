#### crowsnest - A webcam Service for multiple Cams and Stream Services.
####
#### Written by Patrick Gehrsitz aka mryel00 <mryel00.github@gmail.com>
#### Copyright 2025 - till today
#### https://github.com/mainsail-crew/crowsnest
####
#### This File is distributed under GPLv3
####

import asyncio
import functools
from abc import ABC, abstractmethod
from configparser import SectionProxy
from typing import Any, Optional

from .. import logger


class Section(ABC):
    section_name = "section"
    keyword = "section"
    available_sections = {}

    # Section looks like this:
    # [<keyword> <name>]
    # param1: value1
    # param2: value2
    def __init__(self, name: str, config_section: SectionProxy) -> None:
        self.name = name
        self.parse_config_section(config_section)
        if not hasattr(self, "section"):
            self.section = f"[{self.section_name} {self.name}]"
        self.initialized = self.check_config_section(config_section)

    # Check if the config section has only valid options
    def check_config_section(self, config_section: SectionProxy) -> bool:
        success = True
        for option, value in config_section.items():
            if option not in self.parameters:
                self.log_warning(
                    f"Parameter '{option}' is not supported by {self.keyword}!"
                )
        for option, value in self.parameters.items():
            if value is None:
                self.log_error(
                    f"Parameter '{option}' incorrectly set or missing but is required!"
                )
                success = False
        return success

    # Parse config according to the needs of the section
    def parse_config_section(
        self, config_section: SectionProxy, *args, **kwargs
    ) -> None:
        self.parameters: dict[str, Any] = {}

    @abstractmethod
    async def execute(self, lock: asyncio.Lock) -> Optional[asyncio.subprocess.Process]:
        raise NotImplementedError("If you see this, something went wrong!!!")

    def __getattr__(self, name):
        """Dynamically handle log method calls (e.g., log_info, log_debug)."""
        if not name.startswith("log_"):
            raise AttributeError(
                f"'{type(self).__name__}' object has no attribute '{name}'"
            )

        log_function = getattr(logger, name, None)

        if not callable(log_function):
            raise AttributeError(
                f"'{type(self).__name__}' object has no attribute '{name}'"
            )

        @functools.wraps(log_function)
        def log_wrapper(msg, prefix="", postfix=""):
            formatted_msg = f"{prefix}{self.section}{postfix}: {msg}"
            log_function(formatted_msg)

        return log_wrapper

    def log_multiline(self, msg, log_func, prefix="", postfix="", *args):
        logger.log_multiline(
            msg, log_func, line_prefix=f"{prefix}{self.section}{postfix}", *args
        )


def load_component(*args, **kwargs) -> Section:
    raise NotImplementedError("If you see this, something went wrong!!!")
