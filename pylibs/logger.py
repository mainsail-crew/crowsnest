#!/usr/bin/python3

import logging
import logging.handlers

import os
import sys

DEV = 10
DEBUG = 15
QUIET = 35

indentation = 6*' '

def setup_logging(log_path, filemode='a', log_level=logging.INFO):
    global logger
    # Create log directory if it does not exist.
    os.makedirs(os.path.dirname(log_path), exist_ok=True)

    # Change DEBUG to DEB and add custom logging level.
    logging.addLevelName(DEV, 'DEV')
    logging.addLevelName(DEBUG, 'DEBUG')
    logging.addLevelName(QUIET, 'QUIET')

    logger = logging.getLogger('crowsnest')
    logger.propagate = False
    formatter = logging.Formatter('[%(asctime)s] %(message)s', datefmt='%d/%m/%y %H:%M:%S')

    # WatchedFileHandler for log file. This handler will reopen the file if it is moved or deleted.
    # filehandler = logging.handlers.WatchedFileHandler(log_path, mode=filemode, encoding='utf-8')
    filehandler = logging.handlers.RotatingFileHandler(log_path, mode=filemode, encoding='utf-8')
    filehandler.setFormatter(formatter)
    logger.addHandler(filehandler)

    # StreamHandler for stdout.
    streamhandler = logging.StreamHandler(sys.stdout)
    streamhandler.setFormatter(formatter)
    logger.addHandler(streamhandler)

    # Set log level.
    logger.setLevel(log_level)

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
