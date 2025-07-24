#!/usr/bin/python3

import textwrap
from configparser import SectionProxy
from abc import ABC
from os import listdir
from os.path import isfile, join

from ..section import Section
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
    missing_bin_txt = textwrap.dedent("""\
        '%s' executable not found!
        Please make sure everything is installed correctly and up to date!
        Run 'make update' inside the crowsnest directory to install and update everything."""
    )

    def parse_config_section(self, config_section: SectionProxy, *args, **kwargs) -> bool:
        super().parse_config_section(config_section, *args, **kwargs)
        self.parameters.update({
            'mode': config_section.get("mode", None),
            'port': config_section.getint("port", None),
            'device': config_section.get("device", None),
            'resolution': config_section.getresolution("resolution", None),
            'max_fps': config_section.getint("max_fps", None),
            'no_proxy': config_section.getboolean("no_proxy", False),
            'custom_flags': config_section.get("custom_flags", ''),
            'v4l2ctl': config_section.get("v4l2ctl", '')
        })
        mode = self.parameters['mode']
        if mode not in Streamer.binaries:
            Streamer.binaries[mode] = utils.get_executable(
                self.binary_names,
                self.binary_paths
            )
        self.binary_path = Streamer.binaries[mode]

    def check_config_section(self, config_section):
        success = super().check_config_section(config_section)
        if self.binary_path is None:
            logger.log_multiline(Streamer.missing_bin_txt % self.parameters['mode'], logger.log_error)
            success = False
        return success

def load_all_streamers():
    streamer_path = 'pylibs/components/streamer'
    streamer_files = [
        f for f in listdir(streamer_path)
        if isfile(join(streamer_path, f)) and f.endswith('.py')
    ]
    for streamer_file in streamer_files:
        streamer_name = streamer_file[:-3]
        try:
            binary_names, binary_paths = utils.load_streamer(
                streamer_name,
                path=streamer_path.replace('/', '.')
            )
        except NotImplementedError:
            continue
        Streamer.binaries[streamer_name] = utils.get_executable(binary_names, binary_paths)

def load_streamer():
    raise NotImplementedError("If you see this, something went wrong!!!")

def load_component(name: str, config_section: SectionProxy):
    raise NotImplementedError("If you see this, something went wrong!!!")
