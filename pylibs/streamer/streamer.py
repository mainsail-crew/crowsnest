from ..section import Section
from ..parameter import Parameter
from configparser import SectionProxy

class Streamer(Section):
    keyword = ''

    def __init__(self, name: str = '') -> None:
        super().__init__(name)

        self.parameters.update({
            'mode': Parameter(str),
            'port': Parameter(int),
            'device': Parameter(),
            'resolution': Parameter(),
            'max_fps': Parameter(int),
            'custom_flags': Parameter(str, ''),
            'v4l2ctl': Parameter(str, '')
        })

def load_module():
    raise NotImplementedError("If you see this, a module is implemented wrong!!!")