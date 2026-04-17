#### crowsnest - A webcam Service for multiple Cams and Stream Services.
####
#### Written by Patrick Gehrsitz aka mryel00 <mryel00.github@gmail.com>
#### Copyright 2025 - till today
#### https://github.com/mainsail-crew/crowsnest
####
#### This File is distributed under GPLv3
####

from typing import List, Optional

from .camera import Camera

_cameras: List[Camera] = []


def get_cam_by_path(path: str) -> Optional[Camera]:
    return next((cam for cam in _cameras if cam.path_equals(path)), None)


def init_camera_type(obj: Camera) -> List[Camera]:
    cams = obj.init_camera_type()
    _cameras.extend(cams)
    return cams
