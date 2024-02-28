import logging
import shutil
# log_config
import re
# log_host_info
import os
from . import core
# log_cams
import sys
from .hwhandler import get_avail_uvc_dev, get_avail_libcamera, get_avail_legacy

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


def log_initial():
    log_quiet('crowsnest - A webcam Service for multiple Cams and Stream Services.')
    command = 'git describe --always --tags'
    version = core.execute_shell_command(command)
    log_quiet(f'Version: {version}')
    log_quiet('Prepare Startup ...')

def log_config(config_path):
    log_info("Print Configfile: '" + config_path + "'")
    with open(config_path, 'r') as file:
        config_txt = file.read()
        # Remove comments
        config_txt = re.sub(r'#.*$', "", config_txt, flags=re.MULTILINE)
        config_txt = config_txt.strip()
        # Split the config file into lines
        log_multiline(config_txt, log_info, indentation)

def log_host_info():
    log_info("Host Information:")
    log_pre = indentation #"Host Info: "

    ### OS Infos
    # OS Version
    distribution = grep('/etc/os-release', 'PRETTY_NAME')
    distribution = distribution.strip().split('=')[1].strip('"')
    log_info(f'Distribution: {distribution}', log_pre)
    
    # Release Version of MainsailOS (if file present)
    try:
        with open('/etc/mainsailos-release', 'r') as file:
            content = file.read()
            log_info(f'Release: {content.strip()}', log_pre)
    except FileNotFoundError:
        pass

    # Kernel Version
    uname = os.uname()
    log_info(f'Kernel: {uname.sysname} {uname.release} {uname.machine}', log_pre)


    ### Host Machine Infos
    # Host model
    model = grep('/proc/cpuinfo', 'Model').split(':')[1].strip()
    if model == '':
        model == grep('/proc/cpuinfo', 'model name').split(':')[1].strip()
    if model == '':
        model = 'Unknown'
    log_info(f'Model: {model}', log_pre)

    # CPU count
    cpu_count = os.cpu_count()
    log_info(f"Available CPU Cores: {cpu_count}", log_pre)

    # Avail mem
    # psutil.virtual_memory().total
    memtotal = grep('/proc/meminfo', 'MemTotal:').split(':')[1].strip()
    log_info(f'Available Memory: {memtotal}', log_pre)

    # Avail disk size
    # Alternative shutil.disk_usage.total
    command = 'LC_ALL=C df -h / | awk \'NR==2 {print $4" / "$2}\''
    disksize = core.execute_shell_command(command)
    log_info(f'Diskspace (avail. / total): {disksize}', log_pre)

def grep(path: str, search: str) -> str:
    with open(path, 'r') as file:
        lines = file.readlines()
        for line in lines:
            if search in line:
                return line
    return ''

def log_cams():
    log_info("Detect available Devices")
    libcamera = get_avail_libcamera()
    uvc = get_avail_uvc_dev()
    legacy = get_avail_legacy()
    total = len(libcamera.keys()) + len(legacy.keys()) + len(uvc.keys())

    if total == 0:
        log_error("No usable Devices Found. Stopping ")
        sys.exit()

    log_info(f"Found {total} total available Device(s)")
    if libcamera:
        log_info(f"Found {len(libcamera.keys())} available 'libcamera' device(s)")
        for path, properties in libcamera.items():
            log_libcamera_dev(path, properties)
    if legacy:
        for path, properties in legacy.items():
            log_info(f"Detected 'Raspicam' Device -> {path}")
            log_uvc_formats(properties)
            log_uvc_v4l2ctrls(properties)
    if uvc:
        log_info(f"Found {len(uvc.keys())} available v4l2 (UVC) camera(s)")
        for path, properties in uvc.items():
            log_info(f"{path} -> {properties['realpath']}", '')
            log_uvc_formats(properties)
            log_uvc_v4l2ctrls(properties)

def log_libcamera_dev(path: str, properties: dict) -> str:
    log_info(f"Detected 'libcamera' device -> {path}")
    log_info(f"Advertised Formats:", '')
    resolutions = properties['resolutions']
    for res in resolutions:
        log_info(f"{res}", indentation)
    log_info(f"Supported Controls:", '')
    controls = properties['controls']
    if controls:
        for name, value in controls.items():
            min, max, default = value.values()
            str_first = f"{name} ({get_type_str(min)})"
            str_second = f"min={min} max={max} default={default}"
            str_indent = (30 - len(str_first)) * ' ' + ': '
            log_info(str_first + str_indent + str_second, indentation)
    else:
        log_info("apt package 'python3-libcamera' is not installed! \
Make sure to install it to log the controls!", indentation)

def get_type_str(obj) -> str:
    return str(type(obj)).split('\'')[1]

def log_uvc_formats(properties: dict) -> None:
    log_info(f"Supported Formats:", '')
    log_multiline(properties['formats'], log_info, indentation)

def log_uvc_v4l2ctrls(properties: dict) -> None:
    log_info(f"Supported Controls:", '')
    log_multiline(properties['v4l2ctrls'], log_info, indentation)