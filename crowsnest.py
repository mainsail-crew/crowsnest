import configparser

config_path = "resources/crowsnest.conf"

config = configparser.ConfigParser()
config.read(config_path)

# Crowsnest config settings
log_path = '/home/pi/printer_data/logs/crowsnest.log'
log_level = 'debug'
delete_log = False



print(config.sections())
for key in config['crowsnest']:
    print(key)
