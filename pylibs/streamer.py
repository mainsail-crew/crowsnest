from .parameter import CN_Parameter

class CN_Streamer:
    def __init__(self, name, parameters: list[CN_Parameter]) -> None:
        self.name = name
        self.parameters = parameters

    def config_check():
        pass
