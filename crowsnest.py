import argparse
import configparser
from pylibs.crowsnest import Crowsnest
from pylibs.core import get_module_class
from pylibs.watchdog import crowsnest_watchdog
import pylibs.logger as logger
import pylibs.logging as logging

import asyncio

parser = argparse.ArgumentParser(
    prog='Crowsnest',
    description='Crowsnest - A webcam daemon for Raspberry Pi OS distributions like MainsailOS'
)
config = configparser.ConfigParser()

parser.add_argument('-c', '--config', help='Path to config file', required=True)
parser.add_argument('-l', '--log_path', help='Path to log file', required=True)

args = parser.parse_args()

watchdog_running = True

def parse_config():
    global crowsnest, config, args
    config_path = args.config
    config.read(config_path)
    crowsnest = Crowsnest('crowsnest')
    crowsnest.parse_config(config['crowsnest'])
    logger.set_log_level(crowsnest.parameters['log_level'].value)

async def start_processes():
    global config, watchdog_running
    sec_objs = []
    sec_exec_tasks = set()

    logger.log_quiet("Try to start configured Cams / Services...")
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
            if section_object.parse_config(config[section]):
                sec_objs.append(section_object)
                logger.log_info(f"Configuration of section [{section}] looks good. Continue ...")
            else:
                logger.log_error(f"Failed to parse config for section [{section}]!")

        for section_object in sec_objs:
            task = asyncio.create_task(section_object.execute())
            sec_exec_tasks.add(task)
            
        for task in sec_exec_tasks:
            if task is not None:
                await task
    except Exception as e:
        print(e)
    finally:
        for task in sec_exec_tasks:
            if task != None:
                task.cancel()
        watchdog_running = False

async def run_watchdog():
    global watchdog_running
    while watchdog_running:
        await asyncio.sleep(120)
        crowsnest_watchdog()


async def main():
    global args
    logger.setup_logging(args.log_path)
    logging.log_initial()

    parse_config()

    logging.log_host_info()
    logging.log_config(args.config)
    logging.log_cams()

    asyncio.gather(start_processes(), run_watchdog())

if __name__ == "__main__":
    loop = asyncio.get_event_loop()
    try:
        loop.run_until_complete(main())
    finally:
        loop.close()
