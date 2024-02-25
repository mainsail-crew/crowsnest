import os
import shutil
import re

from . import core

def get_avail_uvc_dev() -> dict:
    avail_cmd='find /dev/v4l/by-id/ -iname "*index0" 2> /dev/null'
    avail = core.execute_shell_command(avail_cmd)
    cams = {}
    if avail:
        for cam_path in avail.split('\n'):
            cams[cam_path] = {}
            cams[cam_path]['realpath'] = os.path.realpath(cam_path)
            cams[cam_path]['formats'] = get_uvc_formats(cam_path)
            cams[cam_path]['v4l2ctrls'] = get_uvc_v4l2ctrls(cam_path)
    return cams

def get_uvc_formats(cam_path: str) -> str:
    command = f'v4l2-ctl -d {cam_path} --list-formats-ext | sed "1,3d"'
    formats = core.execute_shell_command(command)
    return formats

def get_uvc_v4l2ctrls(cam_path: str) -> str:
    command = f'v4l2-ctl -d {cam_path} --list-ctrls-menus'
    v4l2ctrls = core.execute_shell_command(command)
    return v4l2ctrls

def get_avail_libcamera() -> dict:
    cmd = shutil.which('libcamera-hello')
    if not cmd:
        return {}
    libcam_cmd =f'{cmd} --list-cameras'
    libcam = core.execute_shell_command(libcam_cmd, strip=False)
    libcams = {}
    if 'Available' in libcam:
        for path in get_libcamera_paths(libcam):
            libcams[path] = {
                'resolutions': get_libcamera_resolutions(libcam, path),
                'controls': get_libcamera_controls(path)
            }
        pass
    return libcams

def get_libcamera_paths(libcamera_output: str) -> list:
    return re.findall(r'\((/base.*?)\)', libcamera_output)

def get_libcamera_resolutions(libcamera_output: str, camera_path: str) -> list:
    # Get the resolution list for only one mode
    resolutions = re.findall(
        rf"{camera_path}.*?:.*?: (.*?)(?=\n\n|\n *')",
        libcamera_output, flags=re.DOTALL
    )
    res = []
    if resolutions:
        # Maybe cut out fps? re.sub('\[.*? - ', '[', r.strip())
        res = [r.strip() for r in resolutions[0].split('\n')]
    return res

def get_libcamera_controls(camera_path: str) -> list:
    ctrls = {}
    try:
        from libcamera import CameraManager, Rectangle

        libcam_cm = CameraManager.singleton()
        for cam in libcam_cm.cameras:
            if cam.id != camera_path:
                continue
            for k, v in cam.controls.items():
                def rectangle_to_tuple(rectangle):
                    return (rectangle.x, rectangle.y, rectangle.width, rectangle.height)
                if isinstance(v.min, Rectangle):
                    ctrls[k.name] = {
                        'min': rectangle_to_tuple(v.min),
                        'max': rectangle_to_tuple(v.max),
                        'default': rectangle_to_tuple(v.default)
                    }
                else:
                    ctrls[k.name] = {
                        'min': v.min,
                        'max': v.max,
                        'default': v.default
                    }
    except ImportError:
        pass
    return ctrls


