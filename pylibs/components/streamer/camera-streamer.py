#!/usr/bin/python3

import asyncio

from configparser import SectionProxy

from .streamer import Streamer
from ... import logger, utils, camera

class Camera_Streamer(Streamer):
    keyword = 'camera-streamer'
    binary_names = ['camera-streamer']
    binary_paths = ['bin/camera-streamer']

    def parse_config_section(self, config_section: SectionProxy, *args, **kwargs) -> bool:
        super().parse_config_section(config_section, *args, **kwargs)
        self.parameters.update({
            'enable_rtsp': config_section.getboolean("enable_rtsp", False),
            'rtsp_port': config_section.getint("rtsp_port", 8554)
        })

    async def execute(self, lock: asyncio.Lock):
        if self.parameters['no_proxy']:
            host = '0.0.0.0'
            logger.log_info("Set to 'no_proxy' mode! Using 0.0.0.0!")
        else:
            host = '127.0.0.1'
        port = self.parameters['port']
        width, height = self.parameters['resolution']

        fps = self.parameters['max_fps']
        device = self.parameters['device']
        cam = camera.camera_manager.get_cam_by_path(device)

        streamer_args = [
            '--camera-path=' + device,
            # '--http-listen=' + host,
            '--http-port=' + str(port),
            '--camera-fps=' + str(fps),
            '--camera-width=' + width,
            '--camera-height=' + height,
            '--camera-snapshot.height=' + height,
            '--camera-video.height=' + height,
            '--camera-stream.height=' + height,
            '--camera-auto_reconnect=1'
        ]

        v4l2ctl = self.parameters['v4l2ctl']
        if v4l2ctl:
            prefix = "V4L2 Control: "
            logger.log_quiet(f"Handling done by {self.keyword}", prefix)
            logger.log_quiet(f"Trying to set: {v4l2ctl}", prefix)
            for ctrl in v4l2ctl.split(','):
                streamer_args += [f'--camera-options={ctrl.strip()}']

        # if device.startswith('/base') and 'i2c' in device:
        if isinstance(cam, camera.Libcamera):
            streamer_args += [
                '--camera-type=libcamera',
                '--camera-format=YUYV'
            ]
        # elif device.startswith('/dev/video') or device.startswith('/dev/v4l'):
        elif isinstance(cam, (camera.UVC, camera.Legacy)):
            streamer_args += [
                '--camera-type=v4l2'
            ]
            if cam.has_mjpg_hw_encoder():
                streamer_args += [
                    '--camera-format=MJPEG'
                ]

        if self.parameters['enable_rtsp']:
            streamer_args += [
                '--rtsp-port=' + str(self.parameters['rtsp_port'])
            ]

        # custom flags
        streamer_args += self.parameters['custom_flags'].split()

        cmd = self.binary_path + ' ' + ' '.join(streamer_args)
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

def load_streamer():
    return Camera_Streamer.binary_names, Camera_Streamer.binary_paths

def load_component(name: str, config_section: SectionProxy):
    return Camera_Streamer(name, config_section)
