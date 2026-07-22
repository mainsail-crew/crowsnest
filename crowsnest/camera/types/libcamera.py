#### crowsnest - A webcam Service for multiple Cams and Stream Services.
####
#### Written by Patrick Gehrsitz aka mryel00 <mryel00.github@gmail.com>
#### Copyright 2025 - till today
#### https://github.com/mainsail-crew/crowsnest
####
#### This File is distributed under GPLv3
####

from __future__ import annotations

import re
import shutil
from collections.abc import Sequence
from typing import Any

from ... import utils
from .. import camera


class Libcamera(camera.Camera[list[str]]):
    def __init__(self, path: str, *args, **kwargs) -> None:
        super().__init__(path, *args, **kwargs)
        self.control_values = self._get_controls()
        self.formats = []

    def _get_controls(self) -> dict[str, dict[str, Any]]:
        ctrls: dict[str, dict[str, Any]] = {}
        try:
            from libcamera import (
                CameraManager,  # pyright: ignore[reportAttributeAccessIssue]
                Rectangle,  # pyright: ignore[reportAttributeAccessIssue]
            )
        except ImportError:
            return ctrls

        def parse_value(rectangle: Any) -> Any:
            if isinstance(rectangle, Rectangle):
                return (rectangle.x, rectangle.y, rectangle.width, rectangle.height)
            return rectangle

        libcam_cm = CameraManager.singleton()
        cam = next((cam for cam in libcam_cm.cameras if cam.id == self.path), None)
        if cam is None:
            return ctrls
        for k, v in cam.controls.items():
            ctrls[k.name] = {
                "min": parse_value(v.min),
                "max": parse_value(v.max),
                "default": parse_value(v.default),
            }
        return ctrls

    def _get_formats(self, libcamera_output: str) -> list[str]:
        resolutions = re.findall(
            rf"{self.path}.*?:.*?: (.*?)(?=\n\n|\n *')",
            libcamera_output,
            flags=re.DOTALL,
        )
        res: list[str] = []
        if resolutions:
            res = [r.strip() for r in resolutions[0].split("\n")]
        return res

    def get_formats_string(self) -> str:
        message = ""
        for res in self.formats:
            message += f"{res}\n"
        return message[:-1]

    def get_controls_string(self) -> str:
        if not self.control_values:
            return (
                "apt package 'python3-libcamera' is not installed! "
                "Make sure to install it to log the controls!"
            )
        message = ""
        for name, value in self.control_values.items():
            min, max, default = value.values()
            str_first = f"{name} ({self.get_type_str(min)})"
            str_indent = (30 - len(str_first)) * " " + ": "
            str_second = f"min={min} max={max} default={default}"
            message += str_first + str_indent + str_second + "\n"
        return message.strip()

    def get_type_str(self, obj: Any) -> str:
        return str(type(obj)).split("'")[1]

    @classmethod
    def init_camera_type(cls) -> Sequence[Libcamera]:
        cmd = shutil.which("rpicam-hello") or shutil.which("libcamera-hello")
        if not cmd:
            return []
        libcam_cmd = f"{cmd} --list-cameras"
        libcam = utils.execute_shell_command(libcam_cmd, strip=False, check=False)
        cams: list[Libcamera] = [
            Libcamera(path) for path in re.findall(r"\((/base.*?)\)", libcam)
        ]
        for cam in cams:
            cam.formats = cam._get_formats(libcam)
        return cams
