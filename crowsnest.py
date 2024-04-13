#!/usr/bin/python3

import argparse
import configparser
import asyncio
import signal
import traceback

from pylibs.components.crowsnest import Crowsnest
from pylibs import utils, watchdog, logger, logging_helper

parser = argparse.ArgumentParser(
    prog='Crowsnest',
    description='Crowsnest - A webcam daemon for Raspberry Pi OS distributions like MainsailOS'
)
config = configparser.ConfigParser()

parser.add_argument('-c', '--config', help='Path to config file', required=True)
parser.add_argument('-l', '--log_path', help='Path to log file', required=True)

args = parser.parse_args()

watchdog_running = True

def initial_parse_config():
    global crowsnest, config, args
    config_path = args.config
    try:
        config.read(config_path)
    except configparser.ParsingError as e:
        logger.log_multiline(e.message, logger.log_error)
        logger.log_error("Failed to parse config! Exiting...")
        exit(1)
    crowsnest = Crowsnest('crowsnest')
    if 'crowsnest' not in config or not crowsnest.parse_config_section(config['crowsnest']):
        logger.log_error("Failed to parse config for '[crowsnest]' section! Exiting...")
        exit(1)

async def start_sections():
    global config, sect_exec_tasks
    sect_objs = []
    sect_exec_tasks = set()

    # Catches SIGINT and SIGTERM to exit gracefully and cancel all tasks
    signal.signal(signal.SIGINT, exit_gracefully)
    signal.signal(signal.SIGTERM, exit_gracefully)

    try:
        logger.log_quiet("Try to parse configured Cams / Services...")
        for section in config.sections():
            section_header = section.split(' ')
            section_object = None
            section_keyword = section_header[0]

            # Skip crowsnest section
            if section_keyword == 'crowsnest':
                continue

            section_name = ' '.join(section_header[1:])
            component = utils.load_component(section_keyword, section_name)
            logger.log_quiet(f"Parse configuration of section [{section}] ...")
            if component.parse_config_section(config[section]):
                sect_objs.append(component)
                logger.log_quiet(f"Configuration of section [{section}] looks good. Continue ...")
            else:
                logger.log_error(f"Failed to parse config for section [{section}]! Skipping ...")

        logger.log_quiet("Try to start configured Cams / Services ...")
        if sect_objs:
            lock = asyncio.Lock()
            for section_object in sect_objs:
                task = asyncio.create_task(section_object.execute(lock))
                sect_exec_tasks.add(task)

            # Lets sec_exec_tasks finish first
            await asyncio.sleep(0)
            async with lock:
                logger.log_quiet("... Done!")
        else:
            logger.log_quiet("No Cams / Services to start! Exiting ...")

        for task in sect_exec_tasks:
            if task is not None:
                await task
    except Exception as e:
        logger.log_multiline(traceback.format_exc().strip(), logger.log_error)
    finally:
        for task in sect_exec_tasks:
            if task is not None:
                task.cancel()
        watchdog.running = False
        logger.log_quiet("Shutdown or Killed by User!")
        logger.log_quiet("Please come again :)")
        logger.log_quiet("Goodbye...")

async def exit_gracefully(signum, frame):
    asyncio.sleep(1)

async def main():
    global args, crowsnest
    logger.setup_logging(args.log_path)
    logging_helper.log_initial()

    initial_parse_config()

    if crowsnest.parameters['delete_log'].value:
        logger.logger.handlers.clear()
        logger.setup_logging(args.log_path, 'w')
        logging_helper.log_initial()

    logger.set_log_level(crowsnest.parameters['log_level'].value)

    logging_helper.log_host_info()
    logging_helper.log_config(args.config)
    logging_helper.log_cams()

    task1 = asyncio.create_task(start_sections())
    await asyncio.sleep(0)
    task2 = asyncio.create_task(watchdog.run_watchdog())

    await task1
    if task2:
        task2.cancel()

if __name__ == "__main__":
    loop = asyncio.get_event_loop()
    try:
        loop.run_until_complete(main())
    finally:
        loop.close()
