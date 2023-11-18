from .section import CN_Section
from .parameter import CN_Parameter
from configparser import SectionProxy

import importlib

class CN_Cam(CN_Section):
    keyword = 'cam'
    loaded_modes = {}

    def __init__(self, name: str = '') -> None:
        super().__init__(name)

        self.possible_parameters += [       
            CN_Parameter('mode', str)
        ]

    def parse_config(self, section: SectionProxy):
        # Dynamically import module
        mode = section["mode"].split()[0]
        module = importlib.import_module(f'pylibs.{mode}')
        CN_Cam.loaded_modes[mode] = getattr(module, 'load_module')()

        print(CN_Cam.loaded_modes)
        t = CN_Cam.loaded_modes[mode]('test')
        print(t, t.keyword, t.name)

    def execute():
        pass

def load_module():
    return CN_Cam

#if __name__ == "__main__":
#    print("This is a module and shouldn't be executed directly")
#else:
#    CN_Section.available_sections[CN_Cam.keyword] = CN_Cam
