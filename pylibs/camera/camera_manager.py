#!/usr/bin/python3

from typing import Optional
from .camera import Camera

def get_all_cameras() -> list:
    global cameras
    try:
        cameras
    except NameError:
        cameras = []
    return cameras

def get_cam_by_path(path: str) -> Optional[Camera]:
    global cameras
    for camera in get_all_cameras():
        if camera.path_equals(path):
            return camera
    return None

def init_camera_type(obj: Camera) -> list:
    global cameras
    cams = obj.init_camera_type()
    get_all_cameras().extend(cams)
    return cams
