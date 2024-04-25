import shutil, re

from ... import utils
from .. import camera

class Libcamera(camera.Camera):
    def __init__(self, path) -> None:
        self.path = path
        self.control_values = self._get_controls()
        self.formats = []

    def _get_controls(self) -> str:
        ctrls = {}
        try:
            from libcamera import CameraManager, Rectangle

            def rectangle_to_tuple(rectangle):
                return (rectangle.x, rectangle.y, rectangle.width, rectangle.height)

            libcam_cm = CameraManager.singleton()
            for cam in libcam_cm.cameras:
                if cam.id != self.path:
                    continue
                for k, v in cam.controls.items():
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

    def _get_formats(self, libcamera_output: str) -> list:
        resolutions = re.findall(
            rf"{self.path}.*?:.*?: (.*?)(?=\n\n|\n *')",
            libcamera_output, flags=re.DOTALL
        )
        res = []
        if resolutions:
            res = [r.strip() for r in resolutions[0].split('\n')]
        return res

    def get_formats_string(self) -> str:
        message = ''
        for res in self.formats:
            message += f"{res}\n"
        return message[:-1]

    def get_controls_string(self) -> str:
        if not self.control_values:
            return "apt package 'python3-libcamera' is not installed! " \
                   "Make sure to install it to log the controls!"
        message = ''
        for name, value in self.control_values.items():
            min, max, default = value.values()
            str_first = f"{name} ({self.get_type_str(min)})"
            str_indent = (30 - len(str_first)) * ' ' + ': '
            str_second = f"min={min} max={max} default={default}"
            message += str_first + str_indent + str_second + '\n'
        return message.strip()
    
    def get_type_str(self, obj) -> str:
        return str(type(obj)).split('\'')[1]

    @staticmethod
    def init_camera_type() -> list:
        cmd = shutil.which('libcamera-hello')
        if not cmd:
            return {}
        libcam_cmd =f'{cmd} --list-cameras'
        libcam = utils.execute_shell_command(libcam_cmd, strip=False)
        cams = [Libcamera(path) for path in re.findall(r'\((/base.*?)\)', libcam)]
        for cam in cams:
            cam.formats = cam._get_formats(libcam)
        return cams
