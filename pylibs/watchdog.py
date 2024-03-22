import os
import asyncio
from pylibs import logger

configured_devices: list[str] = []
running = True

def crowsnest_watchdog():
    global configured_devices
    prefix = "Watchdog: "
    lost_devices = []

    for device in configured_devices:
        if device.startswith('/base'):
            continue
        if device not in lost_devices and not os.path.exists(device):
            lost_devices.append(device)
            logger.log_quiet(f"Lost Devicve: '{device}'", prefix)
        elif device in lost_devices and os.path.exists(device):
            lost_devices.remove(device)
            logger.log_quiet(f"Device '{device}' returned.", prefix)

async def run_watchdog():
    global running
    while running:
        await asyncio.sleep(10)
        crowsnest_watchdog()
