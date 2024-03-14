import asyncio

from configparser import SectionProxy
from pylibs.components.section import Section
from pylibs.parameter import Parameter
from pylibs import logger, utils

class Cam(Section):
    section_name = 'cam'
    keyword = 'cam'

    def __init__(self, name: str) -> None:
        super().__init__(name)

        self.parameters.update({
            'mode': Parameter(str)
        })

        self.streamer = None

    def parse_config_section(self, config_section: SectionProxy, *args, **kwargs) -> bool:
        # Dynamically import module
        mode = config_section["mode"].split()[0]
        self.parameters["mode"].set_value(mode)
        self.streamer = utils.load_component(mode,
                                             self.name,
                                             config_section,
                                             path='pylibs.components.streamer')
        if self.streamer:
            return True
        else:
            return False

    async def execute(self, lock: asyncio.Lock):
        if self.streamer is None:
            print("No streamer loaded")
            return
        try:
            await lock.acquire()
            process = await self.streamer.execute(lock)
            await process.wait()
            logger.log_error(f'Start of {self.parameters["mode"].value} [cam {self.name}] failed!')
        except Exception as e:
            pass
        finally:
            if lock.locked():
                lock.release()

def load_component(name: str, config_section: SectionProxy, *args, **kwargs):
    cam = Cam(name)
    if cam.parse_config_section(config_section, *args, **kwargs):
        return cam
    return None
