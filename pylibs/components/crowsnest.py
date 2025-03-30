#!/usr/bin/python3

from .section import Section

from configparser import SectionProxy
import asyncio

class Crowsnest(Section):
    def __init__(self, config_section: SectionProxy) -> None:
        super().__init__('crowsnest', config_section)

    def parse_config_section(self, section: SectionProxy) -> bool:
        super().parse_config_section(section)
        self.parameters.update({
            'log_path': section.get('log_path', None),
            'log_level': section.getloglevel('log_level', 'INFO'),
            'delete_log': section.getboolean('delete_log', False),
            'no_proxy': section.getboolean('no_proxy', False)
        })

    async def execute(self, lock: asyncio.Lock):
        pass

def load_component(name: str, config_section: SectionProxy, *args, **kwargs):
    cn = Crowsnest()
    if cn.parse_config_section(config_section, *args, **kwargs):
        return cn
    return None
