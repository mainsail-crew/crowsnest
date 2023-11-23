from configparser import SectionProxy

class Section:
    keyword = 'Section'
    available_sections = {}
    # Section looks like this:
    # [<keyword> <name>]
    # param1
    # param2
    def __init__(self, name: str = '') -> None:
        self.name = name
        self.parameters = {}

    # Parse config according to the needs of the section
    def parse_config(self, section: SectionProxy):
        for parameter in section:
            value = section[parameter]
            if parameter not in self.parameters:
                print(f"Warning: Parameter {parameter} is not supported by {self.keyword}")
                continue
            value = value.split('#')[0].strip()
            self.parameters[parameter] = value

    # Execute section specific stuff, e.g. starting cam
    def execute(self):
        raise NotImplementedError("If you see this, a module is implemented wrong!!!")
