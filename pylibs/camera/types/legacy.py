from . import uvc
from ... import v4l2

class LegacyCamera(uvc.UVCCamera):
    @staticmethod
    def init_camera_type() -> list:
            legacy_path = v4l2.ctl.get_dev_path_by_name('mmal')
            if not legacy_path:
                return []
            return [LegacyCamera(legacy_path)]
