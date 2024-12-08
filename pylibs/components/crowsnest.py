#!/usr/bin/python3

from .section import Section
from ..parameter import Parameter

from configparser import SectionProxy
import asyncio

class Crowsnest(Section):
    def __init__(self, name: str = '') -> None:
        super().__init__(name)

        self.parameters.update({
            'log_path': Parameter(str),
            'log_level': Parameter(str, 'verbose'),
            'delete_log': Parameter(bool, 'True'),  
            'no_proxy': Parameter(bool, 'False')
        })

    def parse_config_section(self, section: SectionProxy) -> bool:
        if not super().parse_config_section(section):
            return False
        log_level = self.parameters['log_level'].value.lower()
        if log_level == 'quiet':
            self.parameters['log_level'].value = 'QUIET'
        elif log_level == 'debug':
            self.parameters['log_level'].value = 'DEBUG'
        elif log_level == 'dev':
            self.parameters['log_level'].value = 'DEV'
        else:
            self.parameters['log_level'].value = 'INFO'
        return True

    async def execute(self, lock: asyncio.Lock):
        pass


def load_component(name: str, config_section: SectionProxy, *args, **kwargs):
    cn = Crowsnest(name)
    if cn.parse_config_section(config_section, *args, **kwargs):
        return cn
    return None
