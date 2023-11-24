from .section import Section
from configparser import SectionProxy
from .parameter import Parameter

import importlib

class Cam(Section):
    keyword = 'cam'
    loaded_modes = {}

    def __init__(self, name: str = '') -> None:
        super().__init__(name)

        self.parameters.update({
            'mode': Parameter()
        })

    def parse_config(self, section: SectionProxy):
        # Dynamically import module
        mode = section["mode"].split()[0]
        module_class
        try:
            module = importlib.import_module(f'pylibs.streamer.{mode}')
            module_class = getattr(module, 'load_module')()
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
