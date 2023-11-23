import argparse
import configparser
import importlib
from pylibs.crowsnest import Crowsnest
from pylibs.section import Section
from pylibs.core import load_module

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

crowsnest = Crowsnest(config['crowsnest'])

print(crowsnest)

for section in config.sections():
    section_header = section.split(' ')
    section_object = None
    section_keyword = section_header[0]

    if section_keyword == 'crowsnest':
        continue

    section_object = load_module('pylibs', section_keyword)
    section_object.parse_config(config[section])


    if section_object == None:
        print(f"Section [{section}] couldn't get parsed")
    sections.append(section_object)

k = Section('k')
k1 = Section('k1')

k.keyword = 'test'
Section.keyword='test2'

k2 = Section('k2')
print(Section.keyword, k.keyword)
