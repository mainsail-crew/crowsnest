from .parameter import CN_Parameter

class CN_Section:

    # Section looks like this:
    # [<keyword> <name>]
    # param1
    # param2
    def __init__(self, keyword: str, parameters: list[CN_Parameter], name: str = '') -> None:
        self.keyword = keyword
        self.parameters = parameters
        self.name = name

    # Parse config according to the needs of the section
    def parse_config():
        pass

    # Execute section specific stuff, e.g. starting cam
    def execute():
        pass
