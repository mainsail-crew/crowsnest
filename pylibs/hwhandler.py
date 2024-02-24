import os

from . import core

def get_avail_usb_cams() -> dict:
    avail_cmd='find /dev/v4l/by-id/ -iname "*index0" 2> /dev/null'
    avail = core.execute_shell_command(avail_cmd)
    count = len(avail.readlines())
    cams = {}
    if count > 0:
        for cam_path in avail.split('\n'):
            cams[cam_path] = {}
            cams[cam_path]['realpath'] = os.path.reaelpath(cam_path)
            cams[cam_path]['formats'] = get_usb_cam_formats(cam_path)
            cams[cam_path]['v4l2ctrls'] = get_usb_cam_v4l2ctrls(cam_path)
    return cams

def get_usb_cam_formats(cam_path) -> str:
    command = f'v4l2-ctl -d {cam_path} --list-formats-ext | sed "1,3d"'
    formats = core.execute_shell_command(command)
    return formats

def get_usb_cam_v4l2ctrls(cam_path) -> str:
    command = f'v4l2-ctl -d {cam_path} --list-ctrls-menus'
    v4l2ctrls = core.execute_shell_command(command)
    return v4l2ctrls
