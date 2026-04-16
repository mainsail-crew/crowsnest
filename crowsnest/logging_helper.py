#### crowsnest - A webcam Service for multiple Cams and Stream Services.
####
#### Written by Patrick Gehrsitz aka mryel00 <mryel00.github@gmail.com>
#### Copyright 2025 - till today
#### https://github.com/mainsail-crew/crowsnest
####
#### This File is distributed under GPLv3
####

import os
import re
import shutil
import sys

from . import camera, logger, utils
from .components.streamer.streamer import Streamer, load_all_streamers


def log_initial():
    logger.log_quiet(
        "crowsnest - A webcam Service for multiple Cams and Stream Services."
    )
    command = "git describe --always --tags"
    version = utils.execute_shell_command(command)
    logger.log_quiet(f"Version: {version}")
    logger.log_quiet("Prepare Startup ...")


def log_host_info():
    logger.log_info("Host Information:")
    log_pre = logger.indentation

    ### OS Infos
    # OS Version
    distribution = utils.grep("/etc/os-release", "PRETTY_NAME").strip()
    _, _, distribution = distribution.partition("=")
    distribution = distribution.strip('"') or "Unknown"
    logger.log_info_silent(f"Distribution: {distribution}", log_pre)

    # Release Version of MainsailOS (if file present)
    try:
        with open("/etc/mainsailos-release", "r") as file:
            content = file.read()
            logger.log_info_silent(f"Release: {content.strip()}", log_pre)
    except FileNotFoundError:
        pass

    # Kernel Version
    uname = os.uname()
    logger.log_info_silent(
        f"Kernel: {uname.sysname} {uname.release} {uname.machine}", log_pre
    )

    ### Host Machine Infos
    # Host model
    model = utils.grep("/proc/cpuinfo", "Model").split(":")
    if len(model) == 1:
        model = utils.grep("/proc/cpuinfo", "model name").split(":")
    if len(model) == 1:
        model = "Unknown"
    else:
        model = model[1].strip()

    logger.log_info_silent(f"Model: {model}", log_pre)

    # CPU count
    cpu_count = os.cpu_count()
    logger.log_info_silent(f"Available CPU Cores: {cpu_count}", log_pre)

    # Avail mem
    memtotal = utils.grep("/proc/meminfo", "MemTotal:")
    _, _, memtotal = memtotal.partition(":")
    memtotal = memtotal.strip() or "Unknown"
    logger.log_info_silent(f"Available Memory: {memtotal}", log_pre)

    # Avail disk size
    total, _, free = shutil.disk_usage("/")
    total = utils.bytes_to_gigabytes(total)
    free = utils.bytes_to_gigabytes(free)
    logger.log_info_silent(f"Diskspace (avail. / total): {free}G / {total}G", log_pre)


def log_streamer():
    logger.log_info("Found Streamer:")
    load_all_streamers()
    log_pre = logger.indentation
    for bin in Streamer.binaries:
        if Streamer.binaries[bin] is None:
            continue
        logger.log_info_silent(f"{bin}: {Streamer.binaries[bin]}", log_pre)


def log_config(config_path):
    logger.log_info(f"Print Configfile: '{config_path}'")
    with open(config_path, "r") as file:
        config_txt = file.read()
        # Remove comments
        config_txt = re.sub(r"#.*$", "", config_txt, flags=re.MULTILINE)
        # Remove multiple whitespaces next to each other at the end of a line
        config_txt = re.sub(r"\s*$", "", config_txt, flags=re.MULTILINE)
        # Add newlines before sections
        config_txt = re.sub(r"(\[.*\])$", "\n\\1", config_txt, flags=re.MULTILINE)
        # Remove leading and trailing whitespaces
        config_txt = config_txt.strip()
        # Split the config file into lines
        logger.log_multiline(
            config_txt, logger.log_info_silent, prefix=logger.indentation
        )


def log_cams():
    logger.log_info("Detect available Devices")
    libcamera = camera.camera_manager.init_camera_type(camera.Libcamera)
    uvc = camera.camera_manager.init_camera_type(camera.UVC)
    legacy = camera.camera_manager.init_camera_type(camera.Legacy)
    total = len(libcamera) + len(legacy) + len(uvc)

    if total == 0:
        logger.log_error("No usable Devices Found. Stopping ")
        sys.exit(1)

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
    logger.log_info_silent(f"Advertised Formats:")
    log_camera_formats(cam)
    logger.log_info_silent(f"Supported Controls:")
    log_camera_ctrls(cam)


def log_uvc_cam(cam: camera.UVC) -> None:
    if cam.path_by_id:
        logger.log_info_silent(f"{cam.path_by_id} -> {cam.path}")
    elif cam.path_by_path:
        logger.log_info_silent(f"{cam.path_by_path} -> {cam.path}")
    else:
        logger.log_info_silent(f"{cam.path}")
    logger.log_info_silent(f"Supported Formats:")
    log_camera_formats(cam)
    logger.log_info_silent(f"Supported Controls:")
    log_camera_ctrls(cam)


def log_legacy_cam(cam: camera.Legacy) -> None:
    logger.log_info(f"Detected 'Raspicam' Device -> {cam.path}")
    logger.log_info_silent(f"Supported Formats:")
    log_camera_formats(cam)
    logger.log_info_silent(f"Supported Controls:")
    log_camera_ctrls(cam)


def log_camera_formats(cam: camera.Camera) -> None:
    logger.log_multiline(
        cam.get_formats_string(), logger.log_info_silent, logger.indentation
    )


def log_camera_ctrls(cam: camera.Camera) -> None:
    logger.log_multiline(
        cam.get_controls_string(), logger.log_info_silent, logger.indentation
    )


def log_camera_not_found(streamer: Streamer, wrong_cam_type: bool = False):
    if wrong_cam_type:
        first_sentence = "Wrong camera type or device not found."
    else:
        first_sentence = "Device not found."
    streamer.log_warning(
        f"{first_sentence} Make sure the device path is correct "
        f"and points to a camera supported by {streamer.keyword}!"
    )
