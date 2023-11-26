from configparser import SectionProxy
from .section import Section
from .parameter import Parameter
from .core import get_module_class

import copy

class Cam(Section):
    keyword = 'cam'

    def __init__(self, name: str = '') -> None:
        super().__init__(name)

        self.parameters.update({
            'mode': Parameter()
        })

        self.streamer = None

    def parse_config(self, config_section: SectionProxy, *args, **kwargs):
        # Dynamically import module
        mode = config_section["mode"].split()[0]
        mode_class = get_module_class('pylibs.streamer', mode)
        self.streamer = mode_class(self.name)
        self.streamer.parse_config(config_section)

    async def execute(self):
        if self.streamer is None:
            print("No streamer loaded")
            return
        process = stdout_task = stderr_task = None
        try:
            process, stdout_task, stderr_task = await self.streamer.execute()
            await process.wait()
            await stdout_task.wait()
            await stderr_task.wait()
        except:
            if process != None:
                await process.terminate()
            if stdout_task != None:
                await stdout_task.terminate()
            if stderr_task != None:
                await stderr_task.terminate()

def load_module():
    return Cam

#if __name__ == "__main__":
#    print("This is a module and shouldn't be executed directly")
#else:
#    CN_Section.available_sections[CN_Cam.keyword] = CN_Cam
