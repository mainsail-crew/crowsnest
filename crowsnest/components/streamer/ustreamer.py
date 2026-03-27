#### crowsnest - A webcam Service for multiple Cams and Stream Services.
####
#### Written by Patrick Gehrsitz aka mryel00 <mryel00.github@gmail.com>
#### Copyright 2025 - till today
#### https://github.com/mainsail-crew/crowsnest
####
#### This File is distributed under GPLv3
####

import asyncio
import re
from configparser import SectionProxy
from typing import Optional

from crowsnest.camera.types.uvc import UVC

from ... import camera, logger, utils
from .streamer import Streamer


class Ustreamer(Streamer):
    keyword = "ustreamer"
    binary_names = ["ustreamer.bin", "ustreamer"]
    binary_paths = ["bin/ustreamer"]

    async def execute(self, lock: asyncio.Lock) -> Optional[asyncio.subprocess.Process]:
        host = "127.0.0.1"
        if self.parameters["no_proxy"]:
            host = "0.0.0.0"
            self.log_info("Set to 'no_proxy' mode! Using 0.0.0.0!")

        port = self.parameters["port"]
        res = "x".join(self.parameters["resolution"])
        fps = self.parameters["max_fps"]
        device = self.parameters["device"]
        self.cam = camera.camera_manager.get_cam_by_path(device)
        if not isinstance(self.cam, UVC):
            self.log_warning(
                "Wrong camera type or device not found. Make sure the device path "
                "is correct and points to a camera supported by ustreamer!"
            )
            return None

        streamer_args = [
            f"--host {host}",
            f"--port {port}",
            f"--resolution {res}",
            f"--desired-fps {fps}",
            # webroot & allow crossdomain requests
            "--allow-origin *",
            '--static "resources/ustreamer-www"',
        ]

        if self._is_device_legacy():
            streamer_args.extend(
                [
                    "--format MJPEG",
                    "--device-timeout 5",
                    "--buffers 3",
                ]
            )
            self._blockyfix()
        else:
            streamer_args.extend([f"--device {device}", "--device-timeout 2"])
            if self.cam.has_mjpg_hw_encoder():
                streamer_args.extend(["--format MJPEG", "--encoder HW"])

        v4l2ctl = self.parameters["v4l2ctl"]
        if v4l2ctl:
            self._set_v4l2_ctrls(v4l2ctl.split(","))

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
            error_log_func=self._custom_log,
        )
        if lock.locked():
            lock.release()

        await asyncio.sleep(0.5)
        for ctl in v4l2ctl.split(","):
            if "focus_absolute" in ctl:
                focus_absolute = ctl.split("=")[1].strip()
                self._brokenfocus(focus_absolute)
                break

        return process

    def _custom_log(self, msg: str, prefix=""):
        if msg.endswith("==="):
            msg = msg[:-28]
        else:
            msg = re.sub(r"-- (.*?) \[.*?\] --", r"\1", msg)
        self.log_debug(msg, prefix)

    def _set_v4l2_ctrl(self, ctrl: str, postfix="") -> None:
        try:
            c = ctrl.split("=")[0].strip().lower()
            v = int(ctrl.split("=")[1].strip())
            if not self.cam or not self.cam.set_control(c, v):
                raise ValueError
        except (ValueError, IndexError):
            self.log_quiet(
                f"Failed to set parameter: '{ctrl.strip()}'", postfix=postfix
            )

    def _set_v4l2_ctrls(self, ctrls: Optional[list[str]] = None) -> None:
        postfix = " V4L2 Control"
        if not ctrls:
            self.log_quiet(f"No parameters set. Skipped.", postfix=postfix)
            return
        self.log_quiet(f"Options: {', '.join(ctrls)}", postfix=postfix)
        avail_ctrls = self.cam.get_controls_string()
        for ctrl in ctrls:
            c = ctrl.split("=")[0].strip().lower()
            # TODO: make check more robust
            if c not in avail_ctrls:
                self.log_quiet(
                    f"Parameter '{ctrl.strip()}' not available for '{self.parameters['device']}'. Skipped.",
                    postfix=postfix,
                )
                continue
            self._set_v4l2_ctrl(ctrl, postfix)
        # Repulls the string to print current values
        self.log_multiline(
            self.cam.get_controls_string(),
            logger.log_debug,
            postfix=" v4l2ctl",
        )

    def _brokenfocus(self, focus_absolute_conf: str) -> None:
        cur_val = self.cam.get_current_control_value("focus_absolute")
        if cur_val is not None and cur_val != int(focus_absolute_conf):
            self.log_warning(f"Detected 'brokenfocus' device.")
            self.log_info(f"Try to set to configured Value.")
            self._set_v4l2_ctrl(f"focus_absolute={focus_absolute_conf}")
            self.log_debug(
                f"Value is now: {self.cam.get_current_control_value('focus_absolute')}"
            )

    def _blockyfix(self):
        """
        This function is to set bitrate on legacy raspicams.
        If legacy raspicams set to variable bitrate, they tend to show
        a "block-like" view after reboots
        To prevent that blockyfix should apply constant bitrate before start of ustreamer
        See https://github.com/mainsail-crew/crowsnest/issues/33
        """
        self.cam.set_control("video_bitrate_mode", 1)
        self.cam.set_control("video_bitrate", 15000000)
        self.log_info("Blockyfix: Setting video_bitrate_mode to constant.")

    def _is_device_legacy(self) -> bool:
        return isinstance(self.cam, camera.Legacy)


def load_streamer() -> tuple[list[str], list[str]]:
    return Ustreamer.binary_names, Ustreamer.binary_paths


def load_component(name: str, config_section: SectionProxy) -> Ustreamer:
    return Ustreamer(name, config_section)
