import os
from v4l2py import Device



print(os.popen('v4l2-ctl --list-devices').read())
