#!/usr/bin/python3

import re
import asyncio

from .streamer import Streamer
from ... import logger, utils, camera

class Ustreamer(Streamer):
    keyword = 'ustreamer'

    def __init__(self, name: str) -> None:
        super().__init__(name)

        self.binary_names = ['ustreamer.bin', 'ustreamer']
        self.binary_paths = ['bin/ustreamer']
        self.cam = None

    async def execute(self, lock: asyncio.Lock):
        if self.parameters['no_proxy'].value:
            host = '0.0.0.0'
            logger.log_info("Set to 'no_proxy' mode! Using 0.0.0.0!")
        else:
            host = '127.0.0.1'
        port = self.parameters['port'].value
        res = self.parameters['resolution'].value
        fps = self.parameters['max_fps'].value
        device = self.parameters['device'].value
        self.cam = camera.camera_manager.get_cam_by_path(device)

        streamer_args = [
            '--host', host,
            '--port', str(port),
            '--resolution', str(res),
            '--desired-fps', str(fps),
            # webroot & allow crossdomain requests
            '--allow-origin', '\*',
            '--static', '"ustreamer-www"'
        ]

        if self._is_device_legacy():
            streamer_args += [
                '--format', 'MJPEG',
                '--device-timeout', '5',
                '--buffers', '3'
            ]
            self._blockyfix()
        else:
            streamer_args += [
                '--device', device,
                '--device-timeout', '2'
            ]
            if self.cam and self.cam.has_mjpg_hw_encoder():
                streamer_args += [
                    '--format', 'MJPEG',
                    '--encoder', 'HW'
                ]

        v4l2ctl = self.parameters['v4l2ctl'].value
        if v4l2ctl:
            self._set_v4l2ctrls(self.cam, v4l2ctl.split(','))

        # custom flags
        streamer_args += self.parameters['custom_flags'].value.split()

        cmd = self.binary_path + ' ' + ' '.join(streamer_args)
        log_pre = f'{self.keyword} [cam {self.name}]: '

        logger.log_debug(log_pre + f"Parameters: {' '.join(streamer_args)}")
        process,_,_ = await utils.execute_command(
            cmd,
            info_log_pre=log_pre,
            info_log_func=logger.log_debug,
            error_log_pre=log_pre,
            error_log_func=self._custom_log
        )
        if lock.locked():
            lock.release()

        await asyncio.sleep(0.5)
        for ctl in v4l2ctl.split(','):
            if 'focus_absolute' in ctl:
                focus_absolute = ctl.split('=')[1].strip()
                self._brokenfocus(focus_absolute)
                break

        return process

    def _custom_log(self, msg: str):
        if msg.endswith('==='):
            msg = msg[:-28]
        else:
            msg = re.sub(r'-- (.*?) \[.*?\] --', r'\1', msg)
        logger.log_debug(msg)

    def _set_v4l2_ctrl(self, ctrl: str, prefix='') -> str:
        try:
            c = ctrl.split('=')[0].strip().lower()
            v = int(ctrl.split('=')[1].strip())
            if not self.cam or not self.cam.set_control(c, v):
                raise ValueError
        except (ValueError, IndexError):
            logger.log_quiet(f"Failed to set parameter: '{ctrl.strip()}'", prefix)

    def _set_v4l2ctrls(self, ctrls: list[str] = None) -> str:
        section = f'[cam {self.name}]'
        prefix = "V4L2 Control: "
        if not ctrls:
            logger.log_quiet(f"No parameters set for {section}. Skipped.", prefix)
            return
        logger.log_quiet(f"Device: {section}", prefix)
        logger.log_quiet(f"Options: {', '.join(ctrls)}", prefix)
        avail_ctrls = self.cam.get_controls_string()
        for ctrl in ctrls:
            c = ctrl.split('=')[0].strip().lower()
            if c not in avail_ctrls:
                logger.log_quiet(
                    f"Parameter '{ctrl.strip()}' not available for '{self.parameters['device'].value}'. Skipped.",
                    prefix
                )
                continue
            self._set_v4l2_ctrl(self.cam, ctrl, prefix)
        # Repulls the string to print current values
        logger.log_multiline(self.cam.get_controls_string(), logger.log_debug, 'DEBUG: v4l2ctl: ')

    def _brokenfocus(self, focus_absolute_conf: str) -> str:
        cur_val = self.cam.get_current_control_value('focus_absolute')
        if cur_val and cur_val != focus_absolute_conf:
            logger.log_warning(f"Detected 'brokenfocus' device.")
            logger.log_info(f"Try to set to configured Value.")
            self.set_v4l2_ctrl(self.cam, f'focus_absolute={focus_absolute_conf}')
            logger.log_debug(f"Value is now: {self.cam.get_current_control_value('focus_absolute')}")

    def _is_device_legacy(self) -> bool:
        return isinstance(self.cam, camera.Legacy)


def load_component(name: str):
    return Ustreamer(name)
