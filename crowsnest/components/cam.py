#### crowsnest - A webcam Service for multiple Cams and Stream Services.
####
#### Written by Patrick Gehrsitz aka mryel00 <mryel00.github@gmail.com>
#### Copyright 2025 - till today
#### https://github.com/mainsail-crew/crowsnest
####
#### This File is distributed under GPLv3
####

import asyncio
import traceback
from configparser import SectionProxy
from typing import Optional

from .. import logger, utils, watchdog
from .section import Section
from .streamer.streamer import Streamer


class Cam(Section):
    section_name = "cam"
    keyword = "cam"

    def parse_config_section(
        self, config_section: SectionProxy, *args, **kwargs
    ) -> None:
        super().parse_config_section(config_section, *args, **kwargs)
        self.parameters.update({"mode": config_section.get("mode", None)})
        component = utils.load_component(
            self.parameters["mode"],
            self.name,
            config_section,
            path="crowsnest.components.streamer",
        )
        if component is None or not isinstance(component, Streamer):
            self.log_error("Tried to load a component that is not a Streamer!")
            return
        self.streamer: Streamer = component

    def check_config_section(self, config_section: SectionProxy) -> bool:
        if not hasattr(self, "streamer"):
            return False
        return self.streamer.initialized

    async def execute(
        self, lock: asyncio.Lock
    ) -> Optional[asyncio.subprocess.Process | int]:
        if self.streamer is None:
            self.log_error("No streamer loaded!")
            return
        try:
            await lock.acquire()
            self.log_quiet(
                f"Start {self.streamer.keyword} with device "
                f"{self.streamer.parameters['device']} ..."
            )
            watchdog.configured_devices.append(self.streamer.parameters["device"])
            process = await self.streamer.execute(lock)
            if process is not None:
                await process.wait()
                return process.returncode
        except Exception:
            self.log_multiline(traceback.format_exc().strip(), logger.log_error)
        finally:
            if self.streamer.parameters["device"] in watchdog.configured_devices:
                watchdog.configured_devices.remove(self.streamer.parameters["device"])
            if lock.locked():
                lock.release()

        self.log_error(f"Start of {self.parameters['mode']} failed!")
        return None


def load_component(name: str, config_section: SectionProxy) -> Cam:
    return Cam(name, config_section)
