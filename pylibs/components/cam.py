import asyncio

from configparser import SectionProxy
from pylibs.components.section import Section
from pylibs.components.streamer.streamer import Streamer
from pylibs.parameter import Parameter
from pylibs import logger, utils, watchdog

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
        return self.streamer.parse_config_section(config_section, *args, **kwargs)

    async def execute(self, lock: asyncio.Lock):
        if self.streamer is None:
            print("No streamer loaded")
            return
        try:
            await lock.acquire()
            logger.log_quiet(
                f"Starting {self.streamer.keyword} with device "
                f"{self.streamer.parameters['device'].value} ..."
            )
            watchdog.configured_devices.append(self.streamer.parameters['device'].value)
            process = await self.streamer.execute(lock)
            await process.wait()
            logger.log_error(f'Start of {self.parameters["mode"].value} [cam {self.name}] failed!')
        except Exception as e:
            pass
        finally:
            if lock.locked():
                lock.release()

def load_component(name: str):
    return Cam(name)
