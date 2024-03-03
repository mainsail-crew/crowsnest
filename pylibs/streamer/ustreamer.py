import re
import asyncio

from .streamer import Streamer
from ..core import execute_command, get_executable
from ..hwhandler import is_device_legacy, has_device_mjpg_hw
from ..v4l2_control import set_v4l2ctrls, blockyfix, brokenfocus
from .. import logger

class Ustreamer(Streamer):
    section_name = 'cam'
    keyword = 'ustreamer'

    def __init__(self, name: str = '') -> None:
        super().__init__(name)

        if Ustreamer.binary_path is None:
            Ustreamer.binary_path = get_executable(
                ['ustreamer.bin', 'ustreamer'],
                ['bin/ustreamer']
            )
        self.binary_path = Ustreamer.binary_path

    async def execute(self):
        if not super().execute():
            return None
        if self.parameters['no_proxy'].value:
            host = '0.0.0.0'
            logger.log_info("Set to 'no_proxy' mode! Using 0.0.0.0!")
        else:
            host = '127.0.0.1'
        port = self.parameters['port'].value
        res = self.parameters['resolution'].value
        fps = self.parameters['max_fps'].value
        device = self.parameters['device'].value

        streamer_args = [
            '--host', host,
            '--port', str(port),
            '--resolution', res,
            '--desired-fps', str(fps),
            # webroot & allow crossdomain requests
            '--allow-origin', '\*',
            '--static', '"ustreamer-www"'
        ]

        if is_device_legacy(device):
            streamer_args += [
                '--format', 'MJPEG',
                '--device-timeout', '5',
                '--buffers', '3'
            ]
            blockyfix(device)
        else:
            streamer_args += [
                '--device', device,
                '--device-timeout', '2'
            ]
            if has_device_mjpg_hw(device):
                streamer_args += [
                    '--format', 'MJPEG',
                    '--encoder', 'HW'
                ]

        v4l2ctl = self.parameters['v4l2ctl'].value
        if v4l2ctl:
            set_v4l2ctrls(f'[cam {self.name}]', device, v4l2ctl.split(','))

        # custom flags
        streamer_args += self.parameters['custom_flags'].value.split()

        cmd = self.binary_path + ' ' + ' '.join(streamer_args)
        log_pre = f'ustreamer [cam {self.name}]: '

        # logger.log_quiet(f"Starting ustreamer with device {device} ...")
        logger.log_debug(log_pre + f"Parameters: {' '.join(streamer_args)}")
        process,_,_ = await execute_command(
            cmd,
            error_log_pre=log_pre,
            error_log_func=self.custom_log
        )
        await asyncio.sleep(0.5)

        for ctl in v4l2ctl.split(','):
            if 'focus_absolute' in ctl:
                focus_absolute = ctl.split('=')[1].strip()
                brokenfocus(device, focus_absolute)
                break

        return process

    def custom_log(self, msg: str):
        if msg.endswith('==='):
            msg = msg[:-28]
        else:
            msg = re.sub(r'-- (.*?) \[.*?\] --', r'\1', msg)
        logger.log_debug(msg)


def load_module():
    return Ustreamer
