#!/usr/bin/python3

import asyncio
from configparser import SectionProxy
from abc import ABC, abstractmethod

from ..parameter import Parameter
from .. import logger

class Section(ABC):
    section_name = 'section'
    keyword = 'section'
    available_sections = {}
    # Section looks like this:
    # [<keyword> <name>]
    # param1: value1
    # param2: value2
    def __init__(self, name: str) -> None:
        self.name = name
        self.parameters: dict[str, Parameter] = {}

    # Parse config according to the needs of the section
    def parse_config_section(self, config_section: SectionProxy, *args, **kwargs) -> bool:
        success = True
        for option, value in config_section.items():
            if option not in self.parameters:
                logger.log_warning(f"Parameter '{option}' is not supported by {self.keyword}!")
                continue
            self.parameters[option].set_value(value)
        for option, value in self.parameters.items():
            if value.value is None:
                logger.log_error(f"Parameter '{option}' incorrectly set or missing in section "
                                 f"[{self.section_name} {self.name}] but is required!")
                success = False
        return success

    @abstractmethod
    async def execute(self, lock: asyncio.Lock):
        pass

def load_component(*args, **kwargs):
    raise NotImplementedError("If you see this, something went wrong!!!")
