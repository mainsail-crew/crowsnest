#!/usr/bin/python3

import asyncio

from .streamer import Streamer
from ...parameter import Parameter
from ... import logger, utils, camera

class Spyglass(Streamer):
    keyword = 'spyglass'

    def __init__(self, name: str) -> None:
        super().__init__(name)

        self.binary_names = ['run.py']
        self.binary_paths = ['bin/spyglass']

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
            '--camera_num=' + device,
            '--bindaddress=' + host,
            '--port=' + str(port),
            '--fps=' + str(fps),
            '--resolution=' + str(res),
            '--stream_url=/?action=stream',
            '--snapshot_url=/?action=snapshot',
        ]

        v4l2ctl = self.parameters['v4l2ctl'].value
        if v4l2ctl:
            prefix = "V4L2 Control: "
            logger.log_quiet(f"Handling done by {self.keyword}", prefix)
            logger.log_quiet(f"Trying to set: {v4l2ctl}", prefix)
            for ctrl in v4l2ctl.split(','):
                streamer_args += [f'--controls={ctrl.strip()}']

        # custom flags
        streamer_args += self.parameters['custom_flags'].value.split()

        venv_path = self.binary_paths[0]+'/.venv/bin/python3'
        cmd = venv_path + ' ' + self.binary_path + ' ' + ' '.join(streamer_args)
        log_pre = f'{self.keyword} [cam {self.name}]: '

        logger.log_debug(log_pre + f"Parameters: {' '.join(streamer_args)}")
        process,_,_ = await utils.execute_command(
            cmd,
            info_log_pre=log_pre,
            info_log_func=logger.log_debug,
            error_log_pre=log_pre,
            error_log_func=logger.log_debug
        )
        if lock.locked():
            lock.release()

        return process


def load_component(name: str):
    return Spyglass(name)
