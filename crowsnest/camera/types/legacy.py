#### crowsnest - A webcam Service for multiple Cams and Stream Services.
####
#### Written by Patrick Gehrsitz aka mryel00 <mryel00.github@gmail.com>
#### Copyright 2025 - till today
#### https://github.com/mainsail-crew/crowsnest
####
#### This File is distributed under GPLv3
####

from ... import v4l2
from . import uvc


class Legacy(uvc.UVC):
    @staticmethod
    def init_camera_type() -> list:
        legacy_path = v4l2.ctl.get_dev_path_by_name("mmal")
        if not legacy_path:
            return []
        return [Legacy(legacy_path)]
