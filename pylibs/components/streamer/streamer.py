import textwrap
from configparser import SectionProxy

from pylibs.components.section import Section
from pylibs.parameter import Parameter
from pylibs import logger, utils

class Streamer(Section):
    binaries = {}

    def __init__(self, name: str) -> None:
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
        self.binary_names = []
        self.binary_paths = []
        self.binary_path = None

        self.missing_bin_txt = textwrap.dedent("""\
            '%s' executable not found!
            Please make sure everything is installed correctly and up to date!
            Run 'make update' inside the crowsnest directory to install and update everything.""")

    def parse_config_section(self, config_section: SectionProxy, *args, **kwargs) -> bool:
        success = super().parse_config_section(config_section, *args, **kwargs)
        if not success:
            return False
        mode = self.parameters['mode'].value
        if mode not in Streamer.binaries:
            Streamer.binaries[mode] = utils.get_executable(
                self.binary_names,
                self.binary_paths
            )
        self.binary_path = Streamer.binaries[mode]
    
        if self.binary_path is None:
            logger.log_multiline(self.missing_bin_txt % self.parameters['mode'].value,
                                 logger.log_error)
            return False
        return True

def load_component(name: str):
    raise NotImplementedError("If you see this, something went wrong!!!")
