import os
import shutil
import re

from pylibs import utils, v4l2_control as v4l2_ctl
from pylibs.v4l2 import ctl

avail_cams = {
    'uvc': {},
    'libcamera': {},
    'legacy': {}
}

def v4l2_qctl_to_dict(device: str) -> dict:
    dev_ctl = ctl.qctrls[device]
    values = {}
    cur_sec = ''
    for control in dev_ctl:
        cur_ctl = dev_ctl[control]
        if not cur_ctl['values']:
            cur_sec = control
            values[cur_sec] = {}
            continue
        values[cur_sec][control] = cur_ctl['values']
    return values

def get_avail_uvc_dev() -> dict:
    uvc_path = '/dev/v4l/by-id/'
    avail_uvc = []
    for file in os.listdir(uvc_path):
        path = os.path.join(uvc_path, file)
        if os.path.islink(path) and path.endswith("index0"):
            avail_uvc.append(path)
    cams = {}
    for cam_path in avail_uvc:
        cams[cam_path] = {}
        cams[cam_path]['realpath'] = os.path.realpath(cam_path)
        ctl.init_device(cam_path)
        cams[cam_path]['formats'] = v4l2_ctl.get_uvc_formats(cam_path)
        cams[cam_path]['v4l2ctrls'] = v4l2_qctl_to_dict(cam_path)
    avail_cams['uvc'].update(cams)
    return cams

def has_device_mjpg_hw(cam_path: str) -> bool:
    global avail_cams
    return 'Motion-JPEG, compressed' in v4l2_ctl.get_uvc_formats(cam_path)

def get_avail_libcamera() -> dict:
    cmd = shutil.which('libcamera-hello')
    if not cmd:
        return {}
    libcam_cmd =f'{cmd} --list-cameras'
    libcam = utils.execute_shell_command(libcam_cmd, strip=False)
    libcams = {}
    if 'Available' in libcam:
        for path in get_libcamera_paths(libcam):
            libcams[path] = {
                'resolutions': get_libcamera_resolutions(libcam, path),
                'controls': get_libcamera_controls(path)
            }
    avail_cams['libcamera'].update(libcams)
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

def get_avail_legacy() -> dict:
    cmd = shutil.which('vcgencmd')
    legacy = {}
    if not cmd:
        return legacy
    count_cmd = f'{cmd} get_camera'
    count = utils.execute_shell_command(count_cmd)
    # Gets the number behind detected: "supported=1 detected=1, libcamera interfaces=0"
    if not count:
        return legacy
    count = count.split('=')[2].split(',')[0]
    if count == '0':
        return legacy
    v4l2_cmd = 'v4l2-ctl --list-devices'
    v4l2 = utils.execute_shell_command(v4l2_cmd) 
    legacy_path = ''
    lines = v4l2.split('\n')
    for i in range(len(lines)):
        if 'mmal' in lines[i]:
            legacy_path = lines[i+1].strip()
            break
    legacy[legacy_path] = {}
    legacy[legacy_path]['formats'] = v4l2_ctl.get_uvc_formats(legacy_path)
    legacy[legacy_path]['v4l2ctrls'] = v4l2_ctl.get_uvc_v4l2ctrls(legacy_path)
    avail_cams['legacy'].update(legacy)
    return legacy

def is_device_legacy(cam_path: str) -> bool:
    global avail_cams
    return cam_path in avail_cams['legacy']
