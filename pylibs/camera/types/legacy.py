from . import uvc
from ... import v4l2

class Legacy(uvc.UVC):
    @staticmethod
    def init_camera_type() -> list:
        legacy_path = v4l2.ctl.get_dev_path_by_name('mmal')
        if not legacy_path:
            return []
        return [Legacy(legacy_path)]
