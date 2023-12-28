from configparser import SectionProxy
from .streamer import Streamer
from ..parameter import Parameter
from ..core import execute_command

class Camera_Streamer(Streamer):
    keyword = 'ustreamer'

    def __init__(self, name: str = '') -> None:
        super().__init__(name)

        self.parameters.update({
            'enable_rtsp': Parameter(bool, False),
            'rtsp_port': Parameter(int, 8554)
        })

        self.binary_path = 'bin/ustreamer/ustreamer'
        
    async def execute(self):
        host = '0.0.0.0' if self.parameters['no_proxy'].value else '127.0.0.1'
        port = self.parameters['port'].value
        res = self.parameters['resolution'].value
        fps = self.parameters['max_fps'].value

        streamer_args = [
            self.binary_path,
            '--host', host,
            '--port', str(port),
            '--resolution', res,
            '--desired-fps', str(fps),
            # webroot & allow crossdomain requests
            '--allow-origin=\*',
            '--static', '"ustreamer-www"',
            '--device', '/dev/video0',
            '--format', 'MJPEG',
            '--encoder', 'HW'
        ]
        
        # custom flags
        streamer_args += self.parameters['custom_flags'].value.split()

        cmd = streamer_args
        info_log_pre = f'DEBUG: ustreamer [{self.name}]: '
        return await execute_command(' '.join(cmd), info_log_pre=info_log_pre)
        #ustreamer = subprocess.Popen(['bin/ustreamer/ustreamer'] + streamer_args, text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)


def load_module():
    return Camera_Streamer
