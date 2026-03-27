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
from typing import Optional

from ... import camera, logger, utils
from .streamer import Streamer


class Camera_Streamer(Streamer):
    keyword = "camera-streamer"
    binary_names = ["camera-streamer"]
    binary_paths = ["bin/camera-streamer"]

    async def execute(self, lock: asyncio.Lock) -> Optional[asyncio.subprocess.Process]:
        if utils.is_pi5():
            self.log_warning("Mode 'camera-streamer' is not supported on Pi5/CM5!")
            self.log_warning(f"Please change the mode of this section.")
            return None

        host = "127.0.0.1"
        if self.parameters["no_proxy"]:
            host = "0.0.0.0"
            self.log_info("Set to 'no_proxy' mode! Using 0.0.0.0!")

        port = self.parameters["port"]
        width, height = self.parameters["resolution"]

        fps = self.parameters["max_fps"]
        device = self.parameters["device"]
        cam = camera.camera_manager.get_cam_by_path(device)
        if cam is None:
            self.log_warning(f"Device '{device}' not found in discovered cameras.")
            self.log_warning(f"Make sure the camera is connected and working.")

        streamer_args = [
            "--camera-path=" + device,
            "--http-listen=" + host,
            "--http-port=" + str(port),
            "--camera-fps=" + str(fps),
            "--camera-width=" + width,
            "--camera-height=" + height,
            "--camera-snapshot.height=" + height,
            "--camera-video.height=" + height,
            "--camera-stream.height=" + height,
            "--camera-auto_reconnect=1",
        ]

        v4l2ctl = self.parameters["v4l2ctl"]
        if v4l2ctl:
            postfix = " V4L2 Control"
            self.log_quiet(f"Handling done by {self.keyword}", postfix=postfix)
            self.log_quiet(f"Trying to set: {v4l2ctl}", postfix=postfix)
            for ctrl in v4l2ctl.split(","):
                streamer_args += [f"--camera-options={ctrl.strip()}"]

        if isinstance(cam, camera.Libcamera):
            streamer_args += ["--camera-type=libcamera", "--camera-format=YUYV"]
        elif isinstance(cam, (camera.UVC, camera.Legacy)):
            streamer_args += ["--camera-type=v4l2"]
            if cam.has_mjpg_hw_encoder():
                streamer_args += ["--camera-format=MJPEG"]

        # custom flags
        streamer_args += self.parameters["custom_flags"].split()

        cmd = self.binary_path + " " + " ".join(streamer_args)
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
    return Camera_Streamer.binary_names, Camera_Streamer.binary_paths


def load_component(name: str, config_section: SectionProxy) -> Camera_Streamer:
    return Camera_Streamer(name, config_section)
