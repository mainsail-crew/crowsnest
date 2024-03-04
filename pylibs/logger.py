import logging

import os

DEV = 10
DEBUG = 15
QUIET = 25

indentation = 6*' '

def setup_logging(log_path, filemode='a'):
    global logger
    # Create log directory if it does not exist.
    os.makedirs(os.path.dirname(log_path), exist_ok=True)

    logging.basicConfig(
        filename=log_path,
        filemode=filemode,
        encoding='utf-8',
        level=logging.INFO,
        format='[%(asctime)s] %(message)s',
        datefmt='%d/%m/%y %H:%M:%S'
    )

    # Change DEBUG to DEB and add custom logging level.
    logging.addLevelName(DEV, 'DEV')
    logging.addLevelName(DEBUG, 'DEBUG')
    logging.addLevelName(QUIET, 'QUIET')
    
    logger = logging.getLogger('crowsnest')

def set_log_level(level):
    global logger
    logger.setLevel(level)

def log_quiet(msg, prefix=''):
    global logger
    logger.log(QUIET, prefix + msg)

def log_info(msg, prefix='INFO: '):
    global logger
    logger.info(prefix + msg)

def log_debug(msg, prefix='DEBUG: '):
    global logger
    logger.log(DEBUG, prefix + msg)

def log_warning(msg, prefix='WARN: '):
    global logger
    logger.warning(prefix + msg)

def log_error(msg, prefix='ERROR: '):
    global logger
    logger.error(prefix + msg)

def log_multiline(msg, log_func, *args):
    lines = msg.split('\n')
    for line in lines:
        log_func(line, *args)
