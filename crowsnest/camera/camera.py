#### crowsnest - A webcam Service for multiple Cams and Stream Services.
####
#### Written by Patrick Gehrsitz aka mryel00 <mryel00.github@gmail.com>
#### Copyright 2025 - till today
#### https://github.com/mainsail-crew/crowsnest
####
#### This File is distributed under GPLv3
####

from __future__ import annotations

import os
from abc import ABC, abstractmethod
from collections import defaultdict
from collections.abc import Sequence
from typing import Any, Generic, TypeVar

CameraT = TypeVar("CameraT", bound="Camera")
FormatsT = TypeVar("FormatsT")


class Camera(ABC, Generic[FormatsT]):
    def __init__(self, path: str, *args, **kwargs) -> None:
        self.path: str = path
        self.control_values: dict[str, dict[str, Any]] = defaultdict(dict)
        self.formats: FormatsT

    def path_equals(self, path: str) -> bool:
        return self.path == os.path.realpath(path)

    @abstractmethod
    def get_formats_string(self) -> str:
        pass

    @abstractmethod
    def get_controls_string(self) -> str:
        pass

    @classmethod
    @abstractmethod
    def init_camera_type(cls: type[CameraT]) -> Sequence[CameraT]:
        pass
