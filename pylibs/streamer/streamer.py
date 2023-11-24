from ..cam import Cam
from ..parameter import Parameter
from configparser import SectionProxy

class Streamer(Cam):
    keyword = ''

    def __init__(self, name: str = '') -> None:
        super().__init__(name)

        self.parameters.update({
            'port': Parameter(int),
            'device': Parameter(),
            'resolution': Parameter(), 
            'max_fps': Parameter(int),
            'custom_flags': Parameter(str, ''),
            'v4l2ctl': Parameter(str, '')
        })

    def parse_config(self, section: SectionProxy):
        return super().super().parse_config(section)

def load_module():
    raise NotImplementedError("If you see this, a module is implemented wrong!!!")