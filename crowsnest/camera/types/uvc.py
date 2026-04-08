#### crowsnest - A webcam Service for multiple Cams and Stream Services.
####
#### Written by Patrick Gehrsitz aka mryel00 <mryel00.github@gmail.com>
#### Copyright 2025 - till today
#### https://github.com/mainsail-crew/crowsnest
####
#### This File is distributed under GPLv3
####

import os

from ... import logger, v4l2
from .. import camera


class UVC(camera.Camera):
    def __init__(self, path: str, *args, **kwargs) -> None:
        super().__init__(path, *args, **kwargs)
        self.path_by_path = None
        self.path_by_id = None
        if path.startswith("/dev/video"):
            other = kwargs.get("other", None)
            if other:
                self.path_by_path = other.get("by_path", None)
                self.path_by_id = other.get("by_id", None)
        else:
            self.path = os.path.realpath(path)
            self.path_by_id = path
        self.query_controls = v4l2.ctl.get_query_controls(self.path)

        cur_sec = ""
        for name, qc in self.query_controls.items():
            parsed_qc = v4l2.ctl.parse_qc_of_path(self.path, qc)
            if not parsed_qc:
                cur_sec = name
                self.control_values[cur_sec] = {}
                continue
            self.control_values[cur_sec][name] = parsed_qc
        self.formats = v4l2.ctl.get_formats(self.path)

    def get_formats_string(self) -> str:
        message = ""
        indent = " " * 8
        for fmt, data in self.formats.items():
            message += f"{fmt}:\n"
            for res, fps_list in data.items():
                message += f"{indent}{res}\n"
                for fps in fps_list:
                    message += f"{indent*2}{fps}\n"
        return message[:-1]

    def has_mjpg_hw_encoder(self) -> bool:
        return any("Motion-JPEG" in fmt for fmt in self.formats.keys())

    def get_controls_string(self) -> str:
        message = ""
        for section, controls in self.control_values.items():
            message += f"{section}:\n"
            for control, data in controls.items():
                line = f"{control} ({data['type']})"
                line += max(0, 35 - len(line)) * " " + ":"
                if data["type"] in ("int",):
                    line += f" min={data['min']} max={data['max']} step={data['step']}"
                line += f" default={data['default']}"
                line += f" value={self.get_current_control_value(control)}"
                if "flags" in data:
                    line += f" flags={data['flags']}"
                message += logger.indentation + line + "\n"
                if "menu" in data:
                    for value, name in data["menu"].items():
                        message += logger.indentation * 2 + f"{value}: {name}\n"
            message += "\n"
        return message[:-1]

    def set_control(self, control: str, value: int) -> bool:
        return v4l2.ctl.set_control_with_qc(
            self.path, self.query_controls[control], value
        )

    def get_current_control_value(self, control: str) -> int:
        return v4l2.ctl.get_control_cur_value_with_qc(
            self.path, self.query_controls[control]
        )

    @staticmethod
    def init_camera_type() -> list:
        def get_avail_uvc(search_path):
            avail_uvc = {}
            if not os.path.exists(search_path):
                return avail_uvc
            for file in os.listdir(search_path):
                dev_path = os.path.join(search_path, file)
                if os.path.islink(dev_path) and dev_path.endswith("index0"):
                    avail_uvc[os.path.realpath(dev_path)] = dev_path
            return avail_uvc

        avail_by_id = get_avail_uvc("/dev/v4l/by-id/")

        avail_uvc_cameras = {
            dev_path: {
                "by_path": by_path,
                "by_id": avail_by_id.get(dev_path, None),
            }
            for dev_path, by_path in get_avail_uvc("/dev/v4l/by-path").items()
            if "usb" in by_path
        }

        return [
            UVC(dev_path, other=other_paths)
            for dev_path, other_paths in avail_uvc_cameras.items()
        ]
