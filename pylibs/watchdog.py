import os
from . import logger

configured_devices = []

def crowsnest_watchdog():
    global configured_devices
    prefix = "Crowsnest Watchdog: "
    lost_devices = []

    for device in configured_devices:
        if not os.path.exists(device):
            lost_devices.append(device)
            logger.log_quiet("Lost Devicve: '{device}'", prefix)
        elif device in lost_devices and os.path.exists(device):
            lost_devices.remove(device)
            logger.log_quiet("Device '{device}' returned.", prefix)
