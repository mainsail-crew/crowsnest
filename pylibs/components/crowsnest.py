from pylibs.components.section import Section
from pylibs.parameter import Parameter

from configparser import SectionProxy

class Crowsnest(Section):
    def __init__(self, name: str = '') -> None:
        super().__init__(name)

        self.parameters.update({
            'log_path': Parameter(),
            'log_level': Parameter(str, 'verbose'),
            'delete_log': Parameter(bool, 'True'),
            'no_proxy': Parameter(bool, 'False')
        })

    def parse_config_section(self, section: SectionProxy):
        super().parse_config_section(section)
        log_level = self.parameters['log_level'].value.lower()
        if log_level == 'quiet':
            self.parameters['log_level'].value = 'QUIET'
        elif log_level == 'debug':
            self.parameters['log_level'].value = 'DEBUG'
        elif log_level == 'dev':
            self.parameters['log_level'].value = 'DEV'
        else:
            self.parameters['log_level'].value = 'INFO'
