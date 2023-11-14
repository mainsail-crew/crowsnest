from .parameter import CN_Parameter

class CN_Section:
    keyword = 'Section'
    # Section looks like this:
    # [<keyword> <name>]
    # param1
    # param2
    def __init__(self, parameters: list[CN_Parameter], name: str = '') -> None:
        self.parameters = parameters
        self.name = name

    def __init__(self, name: str = '') -> None:
        self.name = name

    # Parse config according to the needs of the section
    def parse_config():
        pass

    # Execute section specific stuff, e.g. starting cam
    def execute():
        pass
