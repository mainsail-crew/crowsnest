import configparser
from pylibs.cam import Cam

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

# Use if else or dict as match case isn't available before v3.10
for section in config.sections():
    if section.split(' ')[0] == 'cam':
        cam = Cam()
