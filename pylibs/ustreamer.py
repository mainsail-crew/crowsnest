from .cam import CN_Cam
from .parameter import CN_Parameter
from configparser import SectionProxy

class CN_Ustreamer(CN_Cam):
    keyword = 'ustreamer'

    def __init__(self, name: str = '') -> None:
        super().__init__(name)

        self.possible_parameters += [
            CN_Parameter('port', int),
            CN_Parameter('device', str),
            CN_Parameter('resolution', bool),
            CN_Parameter('max_fps', int),
            CN_Parameter('custom_flags', str, ''),
            CN_Parameter('v4l2ctl', dict, {}),
            CN_Parameter('no_proxy', bool, False)
        ]

    def parse_config(self, section: SectionProxy):
        pass
        
    def execute(self):
        pass

def load_module():
    return CN_Ustreamer
