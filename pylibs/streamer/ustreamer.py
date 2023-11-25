from .streamer import Streamer
from ..parameter import Parameter
import subprocess
import time

class Ustreamer(Streamer):
    keyword = 'ustreamer'

    def __init__(self, name: str = '') -> None:
        super().__init__(name)

        self.parameters.update({
            'no_proxy': Parameter(bool, False)
        })
        
    async def execute(self):
        host = '0.0.0.0' if self.parameters['no_proxy'].value else '127.0.0.1'
        port = self.parameters['port'].value
        res = self.parameters['resolution'].value
        fps = self.parameters['max_fps'].value

        streamer_args = [
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

        ustreamer = subprocess.Popen(['bin/ustreamer/ustreamer'] + streamer_args, text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)


def load_module():
    return Ustreamer
