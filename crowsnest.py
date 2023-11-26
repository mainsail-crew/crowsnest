import argparse
import configparser
from pylibs.crowsnest import Crowsnest
from pylibs.section import Section
from pylibs.core import get_module_class

import logging
import asyncio

parser = argparse.ArgumentParser(
    prog='Crowsnest',
    description='Crowsnest - A webcam daemon for Raspberry Pi OS distributions like MainsailOS'
)

parser.add_argument('-c', '--config', help='Path to config file', required=True)

args = parser.parse_args()


config_path = args.config

config = configparser.ConfigParser()
config.read(config_path)

# Example of printing section and values
for section in config.sections():
    print("Section: " + section)
    for key in config[section]:
        print('Key: '+key+'\t\tValue: '+config[section][key].replace(' ', '').split('#')[0])
print(config)

sections = []

crowsnest = Crowsnest('crowsnest')
crowsnest.parse_config(config['crowsnest'])

logging.basicConfig(
    filename=crowsnest.parameters['log_path'].value,
    encoding='utf-8',
    level=crowsnest.parameters['log_level'].value,
    format='[%(asctime)s] %(levelname)s: %(message)s',
    datefmt='%Y-%m-%d %H:%M:%S'
)

#logging.debug('This message should go to the log file')
#logging.info('So should this')
#logging.warning('And this, too')
#logging.error('And non-ASCII stuff, too, like Øresund and Malmö')

print(crowsnest.name)
processes = []
try:
    for section in config.sections():
        section_header = section.split(' ')
        section_object = None
        section_keyword = section_header[0]

        if section_keyword == 'crowsnest':
            continue

        section_class = get_module_class('pylibs', section_keyword)
        section_name = ' '.join(section_header[1:])
        section_object = section_class(section_name)
        section_object.parse_config(config[section])
        t = asyncio.run(section_object.execute())
        t.wait()

        if section_object == None:
            print(f"Section [{section}] couldn't get parsed")
        sections.append(section_object)
finally:
    for process in processes:
        process.terminate()

k = Section('k')
k1 = Section('k1')

k.keyword = 'test'
Section.keyword='test2'

k2 = Section('k2')
print(Section.keyword, k.keyword)
