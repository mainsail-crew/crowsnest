import configparser
import importlib
from pylibs.cam import Cam
from pylibs.section import Section
from pylibs import *

config_path = "resources/crowsnest.conf"

config = configparser.ConfigParser()
config.read(config_path)

# Crowsnest config settings
log_path = '/home/pi/printer_data/logs/crowsnest.log'
log_level = 'debug'
delete_log = False

# Example of printing section and values
for section in config.sections():
    print("Section: " + section)
    for key in config[section]:
        print('Key: '+key+'\t\tValue: '+config[section][key].replace(' ', '').split('#')[0])
print(config)

sections = []
# Use if else or dict as match case isn't available before v3.10
for section in config.sections():
    section_header = section.split(' ')
    section_object = None
    section_keyword = section_header[0]

    try:
        module = importlib.import_module(f'pylibs.{section_keyword}')
        module_class = getattr(module, 'load_module')()
        Section.available_sections[section_keyword] = module_class
        module_class().parse_config(config[section])
    except (ModuleNotFoundError, AttributeError) as e:
        print(str(e))
        continue

    if section_header[0] == 'crowsnest':
        section_object = 1
    elif section_header[0] == 'cam':
        section_object = Cam(' '.join(section_header[1:]))
        section_object.parse_config(config[section])
        
    if section_object == None:
        raise Exception(f"Section [{section}] couldn't get parsed")
    sections.append(section_object)

k = Section('k')
k1 = Section('k1')

k.keyword = 'test'
Section.keyword='test2'

k2 = Section('k2')
print(Section.keyword, k.keyword)
