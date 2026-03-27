#### crowsnest - A webcam Service for multiple Cams and Stream Services.
####
#### Written by Patrick Gehrsitz aka mryel00 <mryel00.github@gmail.com>
#### Copyright 2025 - till today
#### https://github.com/mainsail-crew/crowsnest
####
#### This File is distributed under GPLv3
####

import asyncio
from configparser import SectionProxy

from ... import camera, utils
from .streamer import Streamer


class Spyglass(Streamer):
    keyword = "spyglass"
    binary_names = ["run.py", "spyglass"]
    binary_paths = ["bin/spyglass"]

    async def execute(self, lock: asyncio.Lock) -> asyncio.subprocess.Process:
        host = "127.0.0.1"
        if self.parameters["no_proxy"]:
            host = "0.0.0.0"
            self.log_info("Set to 'no_proxy' mode! Using 0.0.0.0!")

        port = self.parameters["port"]
        res = "x".join(self.parameters["resolution"])
        fps = self.parameters["max_fps"]
        device = self.parameters["device"]
        cam = camera.camera_manager.get_cam_by_path(device)
        if cam is None:
            self.log_warning(f"Device '{device}' not found in discovered cameras.")
            self.log_warning(f"Make sure the camera is connected and working.")

        try:
            int(device)
            device_option = "camera_num"
        except ValueError:
            device_option = "device"

        streamer_args = [
            f"--{device_option}={device}",
            f"--bindaddress={host}",
            f"--port={port}",
            f"--fps={fps}",
            f"--resolution={res}",
            "--stream_url=/?action=stream",
            "--snapshot_url=/?action=snapshot",
        ]

        v4l2ctl = self.parameters["v4l2ctl"]
        if v4l2ctl:
            postfix = " V4L2 Control"
            self.log_quiet(f"Handling done by {self.keyword}", postfix=postfix)
            self.log_quiet(f"Trying to set: {v4l2ctl}", postfix=postfix)
            for ctrl in v4l2ctl.split(","):
                streamer_args.append(f"--controls={ctrl.strip()}")

        # custom flags
        streamer_args.extend(self.parameters["custom_flags"].split())

        venv_path = ""
        if "run.py" in self.binary_path:
            venv_path = f"{Spyglass.binary_paths[0]}/.venv/bin/python3 "
        cmd = f"{venv_path}{self.binary_path} " + " ".join(streamer_args)
        log_pre = f"{self.keyword} "

        self.log_debug(f"Parameters: {' '.join(streamer_args)}", prefix=log_pre)
        process, _, _ = await utils.execute_command(
            cmd,
            info_log_pre=log_pre,
            info_log_func=self.log_debug,
            error_log_pre=log_pre,
            error_log_func=self.log_debug,
        )
        if lock.locked():
            lock.release()

        return process


def load_streamer() -> tuple[list[str], list[str]]:
    return Spyglass.binary_names, Spyglass.binary_paths


def load_component(name: str, config_section: SectionProxy) -> Spyglass:
    return Spyglass(name, config_section)
