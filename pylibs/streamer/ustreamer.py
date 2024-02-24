import re

from .streamer import Streamer
from ..core import execute_command
from ..logger import log_debug

class Ustreamer(Streamer):
    keyword = 'ustreamer'
    binary_path = None

    def __init__(self, name: str = '') -> None:
        super().__init__(name)

        if Ustreamer.binary_path is None:
            Ustreamer.binary_path = 'bin/ustreamer/ustreamer'
        self.binary_path = Ustreamer.binary_path
        
    async def execute(self):
        if not super().execute():
            return None
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
        log_pre = f'ustreamer [cam {self.name}]: '

        process,_,_ = await execute_command(
            ' '.join(cmd),
            error_log_pre=log_pre,
            error_log_func=log_debug
        )

        return process
    
    def custom_log(self, msg):
        msg = re.sub(r'\[.*?\]', '', msg, count=1)
        log_debug(msg)


def load_module():
    return Ustreamer
