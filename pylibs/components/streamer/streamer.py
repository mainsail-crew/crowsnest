import textwrap
from configparser import SectionProxy

from ..section import Section
from ...parameter import Parameter
from ... import logger, utils

class Resolution():
    def __init__(self, value:str) -> None:
        try:
            self.width, self.height = value.split('x')
        except ValueError:
            raise ValueError("Custom Error", f"'{value}' is not of format '<width>x<height>'! "
                             "Parameter ignored!")

    def __str__(self) -> str:
        return 'x'.join([self.width, self.height])

class Streamer(Section):
    section_name = 'cam'
    binaries = {}

    def __init__(self, name: str) -> None:
        super().__init__(name)

        self.parameters.update({
            'mode': Parameter(str),
            'port': Parameter(int),
            'device': Parameter(str),
            'resolution': Parameter(Resolution),
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
