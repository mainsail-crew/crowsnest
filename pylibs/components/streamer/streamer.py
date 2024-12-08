#!/usr/bin/python3

import textwrap
from configparser import SectionProxy
from abc import ABC
from os import listdir
from os.path import isfile, join

from ..section import Section
from ...parameter import Parameter
from ... import logger, utils

class Resolution():
    def __init__(self, value:str) -> None:
        try:
            self.width, self.height = value.split('x')
        except ValueError:
            raise ValueError("Custom Error", f"'{value}' is not of format '<width>x<height>'!")

    def __str__(self) -> str:
        return 'x'.join([self.width, self.height])

class Streamer(Section, ABC):
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
            Run 'make update' inside the crowsnest directory to install and update everything."""
        )

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

def load_all_streamers():
    streamer_path = 'pylibs/components/streamer'
    streamer_files = [
        f for f in listdir(streamer_path)
        if isfile(join(streamer_path, f)) and f.endswith('.py')
    ]
    for streamer_file in streamer_files:
        streamer_name = streamer_file[:-3]
        try:
            streamer = utils.load_component(streamer_name,
                                            'temp',
                                            path=streamer_path.replace('/', '.'))
        except NotImplementedError:
            continue
        Streamer.binaries[streamer_name] = utils.get_executable(
            streamer.binary_names,
            streamer.binary_paths
        )

def load_component(name: str):
    raise NotImplementedError("If you see this, something went wrong!!!")
