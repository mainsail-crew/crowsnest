from ..section import Section
from ..parameter import Parameter
from .. import logger
from configparser import SectionProxy
import os

class Streamer(Section):
    binary_path = None

    def __init__(self, name: str = '') -> None:
        super().__init__(name)

        self.parameters.update({
            'mode': Parameter(str),
            'port': Parameter(int),
            'device': Parameter(str),
            'resolution': Parameter(str),
            'max_fps': Parameter(int),
            'no_proxy': Parameter(bool, 'False'),
            'custom_flags': Parameter(str, ''),
            'v4l2ctl': Parameter(str, '')
        })
        self.binary_path = None

        self.missing_bin_txt = """\
'%s' executable not found!
Please make sure everything is installed correctly and up to date!
Run 'make update' inside the crowsnest directory to install and update everything."""
    
    def parse_config(self, config_section: SectionProxy, *args, **kwargs) -> bool:
        success = super().parse_config(config_section, *args, **kwargs)
        if self.binary_path is None:
            logger.log_multiline(self.missing_bin_txt % self.parameters['mode'].value, logger.log_error)
            return False
        return success
    
    def execute(self):
        if not os.path.exists(self.binary_path):
            logger.log_multiline(self.missing_bin_txt, logger.log_error)
            return False
        return True

def load_module():
    raise NotImplementedError("If you see this, a Streamer module is implemented wrong!!!")
