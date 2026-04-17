#### crowsnest - A webcam Service for multiple Cams and Stream Services.
####
#### Written by Patrick Gehrsitz aka mryel00 <mryel00.github@gmail.com>
#### Copyright 2025 - till today
#### https://github.com/mainsail-crew/crowsnest
####
#### This File is distributed under GPLv3
####

import asyncio
import os

from . import logger

configured_devices: list[str] = []
lost_devices: list[str] = []
running = True


def crowsnest_watchdog():
    global configured_devices, lost_devices
    prefix = "Watchdog: "

    for device in configured_devices:
        if device.startswith("/base"):
            continue
        if device not in lost_devices and not os.path.exists(device):
            lost_devices.append(device)
            logger.log_quiet(f"Lost Device: '{device}'", prefix)
        elif device in lost_devices and os.path.exists(device):
            lost_devices.remove(device)
            logger.log_quiet(f"Device '{device}' returned.", prefix)


async def run_watchdog():
    global running
    while running:
        crowsnest_watchdog()
        await asyncio.sleep(120)
