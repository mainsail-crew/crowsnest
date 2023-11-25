import re
from configparser import SectionProxy

from .parameter import Parameter

class Section:
    keyword = 'Section'
    available_sections = {}
    # Section looks like this:
    # [<keyword> <name>]
    # param1
    # param2
    def __init__(self, name: str = '') -> None:
        self.name = name
        self.parameters: dict[str, Parameter] = {}

    # Parse config according to the needs of the section
    def parse_config(self, config_section: SectionProxy, *args, **kwargs):
        for parameter in config_section:
            value = config_section[parameter]
            if parameter not in self.parameters:
                print(f"Warning: Parameter {parameter} is not supported by {self.keyword}")
                continue
            value = value.split('#')[0].strip()
            self.parameters[parameter].set_value(value)

    # Execute section specific stuff, e.g. starting cam
    def execute(self):
        raise NotImplementedError("If you see this, a module is implemented wrong!!!")
