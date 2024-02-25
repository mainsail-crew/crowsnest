import logging
import shutil
# log_config
import re
# log_host_info
import os
from . import core
# log_cams
import sys
from .hwhandler import get_avail_uvc_dev, get_avail_libcamera

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
    log_pre = "Host Info: "

    ### OS Infos
    # OS Version
    with open('/etc/os-release', 'r') as file:
        lines = file.readlines()
        for line in lines:
            if line.startswith('PRETTY_NAME'):
                distribution = line.strip().split('=')[1].strip('"')
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
    command = 'grep "Model" /proc/cpuinfo | cut -d\':\' -f2'
    model = core.execute_shell_command(command)
    if model == '':
        command = 'grep "model name" /proc/cpuinfo | cut -d\':\' -f2 | awk NR==1'
        model = core.execute_shell_command(command)
    if model == '':
        model = 'Unknown'
    log_info(f'Model: {model}', log_pre)

    # CPU count
    cpu_count = os.cpu_count()
    log_info(f"Available CPU Cores: {cpu_count}", log_pre)

    # Avail mem
    # psutil.virtual_memory().total
    command = 'grep "MemTotal:" /proc/meminfo | awk \'{print $2" "$3}\''
    memtotal = core.execute_shell_command(command)
    log_info(f'Available Memory: {memtotal}', log_pre)

    # Avail disk size
    # Alternative shutil.disk_usage.total
    command = 'LC_ALL=C df -h / | awk \'NR==2 {print $4" / "$2}\''
    disksize = core.execute_shell_command(command)
    log_info(f'Diskspace (avail. / total): {disksize}', log_pre)

def log_cams():
    log_info("Detect available Devices")
    libcamera = get_avail_libcamera()
    uvc = get_avail_uvc_dev()
    legacy = 0
    total = len(libcamera.keys()) + legacy + len(uvc.keys())

    if total == 0:
        log_error("No usable Devices Found. Stopping ")
        sys.exit()

    log_info(f"Found {total} total available Device(s)")
    if libcamera:
        log_info(f"Found {len(libcamera.keys())} available 'libcamera' device(s)")
        for path, properties in libcamera.items():
            log_libcamera_dev(path, properties)
    if legacy > 0:
        pass
    if uvc:
        log_info(f"Found {len(uvc.keys())} available v4l2 (UVC) camera(s)")
        for path, properties in uvc.items():
            log_uvc_dev(path, properties)

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
            str_first = f"{name} ({get_type_str(min)}):"
            str_second = f"min={min} max={max} default={default}"
            str_indent = (30 - len(str_first)) * ' '
            log_info(str_first + str_indent + str_second, indentation)
    else:
        log_info("apt package 'python3-libcamera' is not installed! \
Make sure to install it to log the controls!", indentation)

def get_type_str(obj):
    return str(type(obj)).split('\'')[1]

def log_uvc_dev(path: str, properties: dict) -> str:
    log_info(f"{path} -> {properties['realpath']}", '')
    log_info(f"Supported Formats:", '')
    log_multiline(properties['formats'], log_info, indentation)
    log_info(f"Supported Controls:", '')
    log_multiline(properties['v4l2ctrls'], log_info, indentation)