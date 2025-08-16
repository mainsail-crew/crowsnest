#!/usr/bin/python3

import asyncio
import traceback

from configparser import SectionProxy
from .section import Section
from .streamer.streamer import Streamer
from .. import logger, utils, watchdog

class Cam(Section):
    section_name = 'cam'
    keyword = 'cam'

    def parse_config_section(self, config_section: SectionProxy, *args, **kwargs) -> bool:
        super().parse_config_section(config_section, *args, **kwargs)
        self.parameters.update({
            'mode': config_section.get("mode", None)
        })
        self.streamer: Streamer = utils.load_component(self.parameters["mode"],
                                                       self.name,
                                                       config_section,
                                                       path='pylibs.components.streamer')

    def check_config_section(self, config_section: SectionProxy) -> bool:
        return bool(self.streamer)

    async def execute(self, lock: asyncio.Lock):
        if self.streamer is None:
            print("No streamer loaded")
            return
        try:
            await lock.acquire()
            logger.log_quiet(
                f"Start {self.streamer.keyword} with device "
                f"{self.streamer.parameters['device']} ..."
            )
            watchdog.configured_devices.append(self.streamer.parameters['device'])
            process = await self.streamer.execute(lock)
            await process.wait()
        except Exception as e:
            logger.log_multiline(traceback.format_exc().strip(), logger.log_error)
            logger.log_error(f"Start of {self.parameters['mode']} [cam {self.name}] failed!")
        finally:
            watchdog.configured_devices.remove(self.streamer.parameters['device'])
            if lock.locked():
                lock.release()

def load_component(name: str, config_section: SectionProxy):
    return Cam(name, config_section)
