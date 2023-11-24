from .section import Section
from .parameter import Parameter

class Crowsnest(Section):
    def __init__(self, name: str = '') -> None:
        super().__init__(name)

        self.parameters.update({
            'log_path': Parameter(),
            'log_level': Parameter(str, 'verbose'),
            'delete_log': Parameter(bool, True),
            'no_proxy': Parameter(bool, False)
        })
