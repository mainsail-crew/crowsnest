from .streamer import Streamer
from ..parameter import Parameter

class Ustreamer(Streamer):
    keyword = 'ustreamer'

    def __init__(self, name: str = '') -> None:
        super().__init__(name)

        self.parameters.update({
            'no_proxy': Parameter(bool, False)
        })
        
    def execute(self):
        pass

def load_module():
    return Ustreamer
