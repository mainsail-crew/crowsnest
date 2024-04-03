import re
import os
import sys
import shutil

from . import utils, logger, camera

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
    libcamera = camera.camera_manager.init_camera_type(camera.Libcamera)
    uvc = camera.camera_manager.init_camera_type(camera.UVC)
    legacy = camera.camera_manager.init_camera_type(camera.Legacy)
    total = len(libcamera) + len(legacy) + len(uvc)

    if total == 0:
        logger.log_error("No usable Devices Found. Stopping ")
        sys.exit()

    logger.log_info(f"Found {total} total available Device(s)")
    if libcamera:
        logger.log_info(f"Found {len(libcamera)} available 'libcamera' device(s)")
        for cam in libcamera:
            log_libcam(cam)
    if legacy:
        for cam in legacy:
            log_legacy_cam(cam)
    if uvc:
        logger.log_info(f"Found {len(uvc)} available v4l2 (UVC) camera(s)")
        for cam in uvc:
            log_uvc_cam(cam)

def log_libcam(cam: camera.Libcamera) -> None:
    logger.log_info(f"Detected 'libcamera' device -> {cam.path}")
    logger.log_info(f"Advertised Formats:", '')
    log_camera_formats(cam)
    logger.log_info(f"Supported Controls:", '')
    log_camera_ctrls(cam)

def log_uvc_cam(cam: camera.UVC) -> None:
    logger.log_info(f"{cam.path_by_id} -> {cam.path}", '')
    logger.log_info(f"Supported Formats:", '')
    log_camera_formats(cam)
    logger.log_info(f"Supported Controls:", '')
    log_camera_ctrls(cam)

def log_legacy_cam(camera_path: str) -> None:
    cam: camera.UVC = camera.camera_manager.get_cam_by_path(camera_path)
    logger.log_info(f"Detected 'Raspicam' Device -> {camera_path}")
    logger.log_info(f"Supported Formats:", '')
    log_camera_formats(cam)
    logger.log_info(f"Supported Controls:", '')
    log_camera_ctrls(cam)

def log_camera_formats(cam: camera.Camera) -> None:
    logger.log_multiline(cam.get_formats_string(), logger.log_info, logger.indentation)

def log_camera_ctrls(cam: camera.Camera) -> None:
    logger.log_multiline(cam.get_controls_string(), logger.log_info, logger.indentation)
