import re
import os
import sys
import shutil

from . import utils, logger, hwhandler
from .v4l2 import ctl

def log_initial():
    logger.log_quiet('crowsnest - A webcam Service for multiple Cams and Stream Services.')
    command = 'git describe --always --tags'
    version = utils.execute_shell_command(command)
    logger.log_quiet(f'Version: {version}')
    logger.log_quiet('Prepare Startup ...')

def log_config(config_path):
    logger.log_info("Print Configfile: '" + config_path + "'")
    with open(config_path, 'r') as file:
        config_txt = file.read()
        # Remove comments
        config_txt = re.sub(r'#.*$', "", config_txt, flags=re.MULTILINE)
        # Remove multiple whitespaces next to each other at the end of a line
        config_txt = re.sub(r'\s*$', "", config_txt, flags=re.MULTILINE)
        # Add newlines before sections
        config_txt = re.sub(r'(\[.*\])$', "\n\\1", config_txt, flags=re.MULTILINE)
        # Remove leading and trailing whitespaces
        config_txt = config_txt.strip()
        # Split the config file into lines
        logger.log_multiline(config_txt, logger.log_info, logger.indentation)

def log_host_info():
    logger.log_info("Host Information:")
    log_pre = logger.indentation

    ### OS Infos
    # OS Version
    distribution = utils.grep('/etc/os-release', 'PRETTY_NAME')
    distribution = distribution.strip().split('=')[1].strip('"')
    logger.log_info(f'Distribution: {distribution}', log_pre)

    # Release Version of MainsailOS (if file present)
    try:
        with open('/etc/mainsailos-release', 'r') as file:
            content = file.read()
            logger.log_info(f'Release: {content.strip()}', log_pre)
    except FileNotFoundError:
        pass

    # Kernel Version
    uname = os.uname()
    logger.log_info(f'Kernel: {uname.sysname} {uname.release} {uname.machine}', log_pre)


    ### Host Machine Infos
    # Host model
    model = utils.grep('/proc/cpuinfo', 'Model').split(':')[1].strip()
    if model == '':
        model == utils.grep('/proc/cpuinfo', 'model name').split(':')[1].strip()
    if model == '':
        model = 'Unknown'
    logger.log_info(f'Model: {model}', log_pre)

    # CPU count
    cpu_count = os.cpu_count()
    logger.log_info(f"Available CPU Cores: {cpu_count}", log_pre)

    # Avail mem
    memtotal = utils.grep('/proc/meminfo', 'MemTotal:').split(':')[1].strip()
    logger.log_info(f'Available Memory: {memtotal}', log_pre)

    # Avail disk size
    total, _, free = shutil.disk_usage("/")
    total = utils.bytes_to_gigabytes(total)
    free = utils.bytes_to_gigabytes(free)
    logger.log_info(f'Diskspace (avail. / total): {free}G / {total}G', log_pre)

def log_cams():
    logger.log_info("Detect available Devices")
    libcamera = hwhandler.get_avail_libcamera()
    uvc = hwhandler.get_avail_uvc_dev()
    legacy = hwhandler.get_avail_legacy()
    total = len(libcamera.keys()) + len(legacy.keys()) + len(uvc.keys())

    if total == 0:
        logger.log_error("No usable Devices Found. Stopping ")
        sys.exit()

    logger.log_info(f"Found {total} total available Device(s)")
    if libcamera:
        logger.log_info(f"Found {len(libcamera.keys())} available 'libcamera' device(s)")
        for path, properties in libcamera.items():
            log_libcamera_dev(path, properties)
    if legacy:
        for path, properties in legacy.items():
            logger.log_info(f"Detected 'Raspicam' Device -> {path}")
            log_uvc_dev(path, properties)
    if uvc:
        logger.log_info(f"Found {len(uvc.keys())} available v4l2 (UVC) camera(s)")
        for path, properties in uvc.items():
            logger.log_info(f"{path} -> {properties['realpath']}", '')
            log_uvc_dev(path, properties)

def log_libcamera_dev(path: str, properties: dict) -> str:
    logger.log_info(f"Detected 'libcamera' device -> {path}")
    logger.log_info(f"Advertised Formats:", '')
    resolutions = properties['resolutions']
    for res in resolutions:
        logger.log_info(f"{res}", logger.indentation)
    logger.log_info(f"Supported Controls:", '')
    controls = properties['controls']
    if controls:
        for name, value in controls.items():
            min, max, default = value.values()
            str_first = f"{name} ({get_type_str(min)})"
            str_second = f"min={min} max={max} default={default}"
            str_indent = (30 - len(str_first)) * ' ' + ': '
            logger.log_info(str_first + str_indent + str_second, logger.indentation)
    else:
        logger.log_info("apt package 'python3-libcamera' is not installed! "
                 "Make sure to install it to log the controls!", logger.indentation)

def get_type_str(obj) -> str:
    return str(type(obj)).split('\'')[1]

def log_uvc_dev(path: str, properties: dict) -> str:
    log_uvc_formats(properties)
    log_uvc_v4l2ctrls(path, properties)

def log_uvc_formats(properties: dict) -> None:
    logger.log_info(f"Supported Formats:", '')
    indent = ' '*8
    for fmt, data in properties['formats'].items():
        logger.log_info(f"{fmt}:", logger.indentation)
        for res, fps_list in data.items():
            logger.log_info(f"{res}", logger.indentation+indent)
            for fps in fps_list:
                logger.log_info(f"{fps}", logger.indentation+indent*2)

def log_uvc_v4l2ctrls(device_path: str, properties: dict) -> None:
    logger.log_info(f"Supported Controls:", '')
    for section, controls in properties['v4l2ctrls'].items():
        logger.log_info(f"{section}:", logger.indentation)
        for control, data in controls.items():
            line = f"{control} ({data['type']})"
            line += (35 - len(line)) * ' ' + ':'
            if data['type'] in ('int'):
                line += f" min={data['min']} max={data['max']} step={data['step']}"
            line += f" default={data['default']}"
            line += f" value={ctl.get_control_cur_value(device_path, control)}"
            if 'flags' in data:
                line += f" flags={data['flags']}"
            logger.log_info(line, logger.indentation*2)
            if 'menu' in data:
                for value, name in data['menu'].items():
                    logger.log_info(f"{value}: {name}", logger.indentation*3)
        logger.log_info('', '')
