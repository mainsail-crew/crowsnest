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
parser.add_argument('-l', '--log_path', help='Path to log file', required=True)

args = parser.parse_args()

def setup_logging():
    logging.basicConfig(
        filename=args.log_path,
        encoding='utf-8',
        level=logging.INFO,
        format='[%(asctime)s] %(levelname)s: %(message)s',
        datefmt='%d/%m/%y %H:%M:%S'
    )

    # Change DEBUG to DEB and add custom DEBUG logging level.
    logging.addLevelName(10, 'DEV')
    logging.addLevelName(15, 'DEBUG')

# Read config
config_path = args.config

config = configparser.ConfigParser()
config.read(config_path)

# Example of printing section and values
# for section in config.sections():
#     print("Section: " + section)
#     for key in config[section]:
#         print('Key: '+key+'\t\tValue: '+config[section][key].replace(' ', '').split('#')[0])
# print(config)


crowsnest = Crowsnest('crowsnest')
crowsnest.parse_config(config['crowsnest'])
logging.getLogger().setLevel(crowsnest.parameters['log_level'].value)

print('Log Level: ' + crowsnest.parameters['log_level'].value)

print(crowsnest.name)

async def start_processes():
    sec_objs = []
    sec_exec_tasks = set()

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
            task = asyncio.create_task(section_object.execute())
            sec_exec_tasks.add(task)
            task.add_done_callback(sec_exec_tasks.discard)

            if section_object == None:
                print(f"Section [{section}] couldn't get parsed")
            sec_objs.append(section_object)
        for task in sec_exec_tasks:
            if task != None:
                await task
    except Exception as e:
        print(e)
    finally:
        for task in sec_exec_tasks:
            if task != None:
                task.cancel()

setup_logging()

# Run async as it will wait for all tasks to finish
asyncio.run(start_processes())
