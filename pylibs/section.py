from configparser import SectionProxy

class CN_Section:
    keyword = 'Section'
    available_sections = {}
    # Section looks like this:
    # [<keyword> <name>]
    # param1
    # param2
    def __init__(self, name: str = '') -> None:
        self.name = name
        self.possible_parameters = []

    # Parse config according to the needs of the section
    def parse_config(self, section: SectionProxy):
        raise NotImplementedError("If you see this a module is implemented wrong!!!")

    # Execute section specific stuff, e.g. starting cam
    def execute(self):
        raise NotImplementedError("If you see this a module is implemented wrong!!!")
