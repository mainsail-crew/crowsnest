import logging

DEV = 10
DEBUG = 15
QUIET = 25

indentation = 6*' '

def setup_logging(log_path):
    logging.basicConfig(
        filename=log_path,
        encoding='utf-8',
        level=logging.INFO,
        format='[%(asctime)s] %(message)s',
        datefmt='%d/%m/%y %H:%M:%S'
    )

    # Change DEBUG to DEB and add custom logging level.
    logging.addLevelName(DEV, 'DEV')
    logging.addLevelName(DEBUG, 'DEBUG')
    logging.addLevelName(QUIET, 'QUIET')

def set_log_level(level):
    logging.getLogger().setLevel(level)

def log_quiet(msg):
    logging.log(QUIET, msg)

def log_info(msg, prefix='INFO: '):
    logging.info(prefix + msg)

def log_debug(msg, prefix='DEBUG: '):
    logging.log(DEBUG, prefix + msg)

def log_error(msg, prefix='ERROR: '):
    logging.error(prefix + msg)

def log_multiline(msg, log_func, *args):
    lines = msg.split('\n')
    for line in lines:
        log_func(line, *args)
