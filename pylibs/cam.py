from .section import Section
from .parameter import Parameter
from configparser import SectionProxy

import importlib

class Cam(Section):
    keyword = 'cam'
    loaded_modes = {}

    def __init__(self, name: str = '') -> None:
        super().__init__(name)

        self.parameters.update({
            'mode': None
        })

        self.possible_parameters += [       
            Parameter('mode', str)
        ]

    def parse_config(self, section: SectionProxy):
        # Dynamically import module
        mode = section["mode"].split()[0]
        try:
            module = importlib.import_module(f'pylibs.{mode}')
            module_class = getattr(module, 'load_module')()
            Cam.loaded_modes[mode] = module_class
            print(Cam.loaded_modes)
            t = Cam.loaded_modes[mode]('test')
            print(t, t.keyword, t.name)
            return module_class(self.name).parse_config(section)
        except (ModuleNotFoundError, AttributeError) as e:
            print(str(e))
            return

    def execute():
        pass

def load_module():
    return Cam

#if __name__ == "__main__":
#    print("This is a module and shouldn't be executed directly")
#else:
#    CN_Section.available_sections[CN_Cam.keyword] = CN_Cam
