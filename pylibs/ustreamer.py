from .cam import Cam
from .parameter import Parameter
from configparser import SectionProxy

class Ustreamer(Cam):
    keyword = 'ustreamer'

    def __init__(self, name: str = '') -> None:
        super().__init__(name)

        self.parameters.update({
            'port': None,
            'device': None,
            'resolution': None, 
            'max_fps': None,
            'custom_flags': '',
            'v4l2ctl': '',
            'no_proxy': False
        })

        self.possible_parameters += [
            Parameter('port', int),
            Parameter('device', str),
            Parameter('resolution', str),
            Parameter('max_fps', int),
            Parameter('custom_flags', str, ''),
            Parameter('v4l2ctl', dict, {}),
            Parameter('no_proxy', bool, False)
        ]

    def parse_config(self, section: SectionProxy):
        for parameter, value in section:
            if parameter not in self.parameters:
                print(f"Warning: Parameter [{parameter}] is not supported by [{self.keyword}]")
                continue
            value = value.split('#')[0].strip()
            self.parameters[parameter] = value

        
    def execute(self):
        pass

def load_module():
    return Ustreamer
