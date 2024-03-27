import re
import asyncio

from .streamer import Streamer
from ... import logger, utils, hwhandler, v4l2_control as v4l2_ctl

class Ustreamer(Streamer):
    keyword = 'ustreamer'

    def __init__(self, name: str) -> None:
        super().__init__(name)

        self.binary_names = ['ustreamer.bin', 'ustreamer']
        self.binary_paths = ['bin/ustreamer']

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

        streamer_args = [
            '--host', host,
            '--port', str(port),
            '--resolution', str(res),
            '--desired-fps', str(fps),
            # webroot & allow crossdomain requests
            '--allow-origin', '\*',
            '--static', '"ustreamer-www"'
        ]

        if hwhandler.is_device_legacy(device):
            streamer_args += [
                '--format', 'MJPEG',
                '--device-timeout', '5',
                '--buffers', '3'
            ]
            v4l2_ctl.blockyfix(device)
        else:
            streamer_args += [
                '--device', device,
                '--device-timeout', '2'
            ]
            if hwhandler.has_device_mjpg_hw(device):
                streamer_args += [
                    '--format', 'MJPEG',
                    '--encoder', 'HW'
                ]

        v4l2ctl = self.parameters['v4l2ctl'].value
        if v4l2ctl:
            v4l2_ctl.set_v4l2ctrls(f'[cam {self.name}]', device, v4l2ctl.split(','))

        # custom flags
        streamer_args += self.parameters['custom_flags'].value.split()

        cmd = self.binary_path + ' ' + ' '.join(streamer_args)
        log_pre = f'ustreamer [cam {self.name}]: '

        logger.log_debug(log_pre + f"Parameters: {' '.join(streamer_args)}")
        process,_,_ = await utils.execute_command(
            cmd,
            info_log_pre=log_pre,
            info_log_func=logger.log_debug,
            error_log_pre=log_pre,
            error_log_func=self.custom_log
        )
        if lock.locked():
            lock.release()

        await asyncio.sleep(0.5)
        for ctl in v4l2ctl.split(','):
            if 'focus_absolute' in ctl:
                focus_absolute = ctl.split('=')[1].strip()
                v4l2_ctl.brokenfocus(device, focus_absolute)
                break

        return process

    def custom_log(self, msg: str):
        if msg.endswith('==='):
            msg = msg[:-28]
        else:
            msg = re.sub(r'-- (.*?) \[.*?\] --', r'\1', msg)
        logger.log_debug(msg)


def load_component(name: str):
    return Ustreamer(name)
