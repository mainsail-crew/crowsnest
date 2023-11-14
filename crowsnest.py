import configparser
from pylibs.cam import CN_Cam
from pylibs.section import CN_Section

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

sections = []
# Use if else or dict as match case isn't available before v3.10
for section in config.sections():
    section_header = section.split(' ')
    section_object = None
    if section_header[0] == 'crowsnest':
        section_object = 1
    elif section_header[0] == 'cam':
        section_object = CN_Cam(' '.join(section_header[1:]))
    if section_object == None:
        raise Exception(f"Section [{section}] couldn't get parsed")
    sections.append(section_object)

k = CN_Section('k')
k1 = CN_Section('k1')

k.keyword = 'test'
CN_Section.keyword='test2'

k2 = CN_Section('k2')
print(CN_Section.keyword, k.keyword)
