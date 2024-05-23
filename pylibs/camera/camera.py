#!/usr/bin/python3

import os
from abc import ABC, abstractmethod

class Camera(ABC):
    def __init__(self, path: str) -> None:
        self.path = path
        self.control_values = {}
        self.formats = {}

    def path_equals(self, path: str) -> bool:
        return self.path == os.path.realpath(path)

    @abstractmethod
    def get_formats_string(self) -> str:
        pass

    @abstractmethod
    def get_controls_string(self) -> str:
        pass

    @staticmethod
    @abstractmethod
    def init_camera_type() -> list:
        pass
