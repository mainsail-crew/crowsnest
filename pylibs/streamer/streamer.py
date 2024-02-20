from ..section import Section
from ..parameter import Parameter
from configparser import SectionProxy
import os
import logging

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
            'no_proxy': Parameter(bool, False),
            'custom_flags': Parameter(str, ''),
            'v4l2ctl': Parameter(str, '')
        })
        self.binary_path = None
    
    def parse_config(self, config_section: SectionProxy, *args, **kwargs):
        super().parse_config(config_section, *args, **kwargs)
        if self.binary_path is None:
            raise Exception("""This shouldn't happen. Please join our discord and open a post inside the support forum!\nhttps://discord.gg/mainsail""")
    
    def execute(self):
        if not os.path.exists(self.binary_path):
            logging.info(f"'{self.binary_path}' not found! Please make sure that everything is installed correctly!")
            return False
        return True

def load_module():
    raise NotImplementedError("If you see this, a module is implemented wrong!!!")