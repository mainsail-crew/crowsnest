import asyncio

from pylibs.components.streamer.streamer import Streamer
from pylibs.parameter import Parameter
from pylibs.utils import execute_command, get_executable
from pylibs.hwhandler import has_device_mjpg_hw
from pylibs import logger

class Camera_Streamer(Streamer):
    keyword = 'camera-streamer'

    def __init__(self, name: str = '') -> None:
        super().__init__(name)

        self.parameters.update({
            'enable_rtsp': Parameter(bool, 'False'),
            'rtsp_port': Parameter(int, 8554)
        })

        if Camera_Streamer.binary_path is None:
            Camera_Streamer.binary_path = get_executable(
                ['camera-streamer'],
                ['bin/camera-streamer']
            )
        self.binary_path = Camera_Streamer.binary_path

    async def execute(self, lock: asyncio.Lock):
        if not await super().execute(lock):
            return None
        if self.parameters['no_proxy'].value:
            host = '0.0.0.0'
            logger.log_info("Set to 'no_proxy' mode! Using 0.0.0.0!")
        else:
            host = '127.0.0.1'
        port = self.parameters['port'].value
        res = self.parameters['resolution'].value.split('x')
        width = res[0]
        height = res[1]

        fps = self.parameters['max_fps'].value
        device = self.parameters['device'].value

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

        v4l2ctl = self.parameters['v4l2ctl'].value
        if v4l2ctl:
            prefix = "V4L2 Control: "
            logger.log_quiet(f"Handling done by camera-streamer", prefix)
            logger.log_quiet(f"Trying to set: {v4l2ctl}", prefix)
            for ctrl in v4l2ctl.split(','):
                streamer_args += [f'--camera-options={ctrl.strip()}']

        if device.startswith('/base') and 'i2c' in device:
            streamer_args += [
                '--camera-type=libcamera',
                '--camera-format=YUYV'
            ]
        elif device.startswith('/dev/video') or device.startswith('/dev/v4l'):
            streamer_args += [
                '--camera-type=v4l2'
            ]
            if has_device_mjpg_hw(device):
                streamer_args += [
                    '--camera-format=MJPEG'
                ]

        if self.parameters['enable_rtsp'].value:
            streamer_args += [
                '--rtsp-port=' + str(self.parameters['rtsp_port'].value)
            ]

        # custom flags
        streamer_args += self.parameters['custom_flags'].value.split()

        cmd = self.binary_path + ' ' + ' '.join(streamer_args)
        log_pre = f'camera-streamer [cam {self.name}]: '

        logger.log_debug(log_pre + f"Parameters: {' '.join(streamer_args)}")
        process,_,_ = await execute_command(
            cmd,
            info_log_pre=log_pre,
            info_log_func=logger.log_debug,
            error_log_pre=log_pre,
            error_log_func=logger.log_debug
        )
        if lock.locked():
            lock.release()

        return process


def load_module():
    return Camera_Streamer
