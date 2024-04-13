#!/usr/bin/python3

import asyncio
import traceback

from configparser import SectionProxy
from .section import Section
from .streamer.streamer import Streamer
from ..parameter import Parameter
from .. import logger, utils, watchdog

class Cam(Section):
    section_name = 'cam'
    keyword = 'cam'

    def __init__(self, name: str) -> None:
        super().__init__(name)

        self.parameters.update({
            'mode': Parameter(str)
        })

        self.streamer: Streamer = None

    def parse_config_section(self, config_section: SectionProxy, *args, **kwargs) -> bool:
        # Dynamically import module
        mode = config_section["mode"].split()[0]
        self.parameters["mode"].set_value(mode)
        self.streamer = utils.load_component(mode,
                                             self.name,
                                             path='pylibs.components.streamer')
        if self.streamer is None:
            return False
        return self.streamer.parse_config_section(config_section, *args, **kwargs)

    async def execute(self, lock: asyncio.Lock):
        if self.streamer is None:
            print("No streamer loaded")
            return
        try:
            await lock.acquire()
            logger.log_quiet(
                f"Start {self.streamer.keyword} with device "
                f"{self.streamer.parameters['device'].value} ..."
            )
            watchdog.configured_devices.append(self.streamer.parameters['device'].value)
            process = await self.streamer.execute(lock)
            await process.wait()
        except Exception as e:
            logger.log_multiline(traceback.format_exc().strip(), logger.log_error)
        finally:
            logger.log_error(f"Start of {self.parameters['mode'].value} [cam {self.name}] failed!")
            watchdog.configured_devices.remove(self.streamer.parameters['device'].value)
            if lock.locked():
                lock.release()

def load_component(name: str):
    return Cam(name)
