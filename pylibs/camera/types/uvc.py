import os

from .. import camera
from ... import v4l2, logger

class UVC(camera.Camera):
    def __init__(self, path: str) -> None:
        if path.startswith('/dev/video'):
            self.path = path
            self.path_by_id = None
        else:
            self.path = os.path.realpath(path)
            self.path_by_id = path
        self.query_controls = v4l2.ctl.get_query_controls(self.path)

        self.control_values = {}
        cur_sec = ''
        for name, qc in self.query_controls.items():
            parsed_qc = v4l2.ctl.parse_qc_of_path(self.path, qc)
            if not parsed_qc:
                cur_sec = name
                self.control_values[cur_sec] = {}
                continue
            self.control_values[cur_sec][name] =  v4l2.ctl.parse_qc_of_path(self.path, qc)
        self.formats = v4l2.ctl.get_formats(self.path)


    def get_formats_string(self) -> str:
        message = ''
        indent = ' '*8
        for fmt, data in self.formats.items():
            message += f"{fmt}:\n"
            for res, fps_list in data.items():
                message += f"{indent}{res}\n"
                for fps in fps_list:
                    message += f"{indent*2}{fps}\n"
        return message[:-1]

    def has_mjpg_hw_encoder(self) -> bool:
        for fmt in self.formats.keys():
            if 'Motion-JPEG' in fmt:
                return True
        return False

    def get_controls_string(self) -> str:
        message = ''
        for section, controls in self.control_values.items():
            message += f"{section}:\n"
            for control, data in controls.items():
                line = f"{control} ({data['type']})"
                line += (35 - len(line)) * ' ' + ':'
                if data['type'] in ('int'):
                    line += f" min={data['min']} max={data['max']} step={data['step']}"
                line += f" default={data['default']}"
                line += f" value={self.get_current_control_value(control)}"
                if 'flags' in data:
                    line += f" flags={data['flags']}"
                message += logger.indentation + line + '\n'
                if 'menu' in data:
                    for value, name in data['menu'].items():
                        message += logger.indentation*2 + f"{value}: {name}\n"
            message += '\n'
        return message[:-1]

    def set_control(self, control: str, value: int) -> bool:
        return v4l2.ctl.set_control_with_qc(self.path, self.query_controls[control], value)

    def get_current_control_value(self, control: str) -> int:
        return v4l2.ctl.get_control_cur_value_with_qc(self.path, self.query_controls[control])

    @staticmethod
    def init_camera_type() -> list:
        def get_avail_uvc(path):
            avail_uvc = []
            for file in os.listdir(path):
                by_id = os.path.join(path, file)
                if os.path.islink(by_id) and by_id.endswith("index0"):
                    avail_uvc.append((by_id, os.path.realpath(by_id)))
            return avail_uvc
        avail_by_id = get_avail_uvc('/dev/v4l/by-id/')
        by_path_path = get_avail_uvc('/dev/v4l/by-path/')
        return [UVC(by_id_path) for by_id_path,_ in avail_by_id]
