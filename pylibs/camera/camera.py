import os

class Camera:
    def __init__(self, path: str) -> None:
        self.path = path
        self.control_values = {}
        self.formats = {}

    def path_equals(self, path: str) -> bool:
        return self.path == os.path.realpath(path)

    def get_formats_string(self) -> str:
        return ''

    def get_controls_string(self) -> str:
        return ''

    @staticmethod
    def init_camera_type() -> list:
        pass
