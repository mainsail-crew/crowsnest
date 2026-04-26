#### crowsnest - A webcam Service for multiple Cams and Stream Services.
####
#### Written by Patrick Gehrsitz aka mryel00 <mryel00.github@gmail.com>
#### Copyright 2025 - till today
#### https://github.com/mainsail-crew/crowsnest
####
#### This File is distributed under GPLv3
####

import asyncio
import importlib
import os
import shlex
import shutil
import subprocess
from configparser import SectionProxy
from typing import Any, Callable, Optional

from . import logger


# Dynamically import functions
# Requires module to have a function with function_name
def load_function(
    function_name: str, module_name: str, path="crowsnest.components"
) -> Callable[..., Any]:
    module = importlib.import_module(f"{path}.{module_name}")
    return getattr(module, function_name)


def load_component(
    module_name: str,
    name: str,
    config_section: SectionProxy,
    path="crowsnest.components",
) -> Optional[Any]:
    try:
        return load_function("load_component", module_name, path)(name, config_section)
    except (ModuleNotFoundError, AttributeError) as e:
        logger.log_error(
            f"Failed to load module '{module_name}' from '{path}' ({e.name})"
        )
    return None


def load_streamer(module_name: str, path="crowsnest.components") -> Optional[Any]:
    try:
        return load_function("load_streamer", module_name, path)()
    except (ModuleNotFoundError, AttributeError) as e:
        logger.log_error(
            f"Failed to load streamer '{module_name}' from '{path}' ({e.name})"
        )
    return None


async def log_subprocess_output(stream, log_func, line_prefix=""):
    line = await stream.readline()
    while line:
        l = line.decode("utf-8").strip()
        log_func(l, prefix=line_prefix)
        line = await stream.readline()


async def execute_command(
    command: str,
    info_log_func=logger.log_debug,
    error_log_func=logger.log_error,
    info_log_pre="",
    error_log_pre="",
):
    args = shlex.split(command)
    process = await asyncio.create_subprocess_exec(
        *args, stdout=asyncio.subprocess.PIPE, stderr=asyncio.subprocess.PIPE
    )

    stdout_task = asyncio.create_task(
        log_subprocess_output(process.stdout, info_log_func, info_log_pre)
    )
    stderr_task = asyncio.create_task(
        log_subprocess_output(process.stderr, error_log_func, error_log_pre)
    )

    return process, stdout_task, stderr_task


def execute_shell_command(command: str, strip: bool = True, check: bool = True) -> str:
    try:
        output = subprocess.run(
            shlex.split(command),
            stdout=subprocess.PIPE,
            stderr=subprocess.DEVNULL,
            text=True,
            check=check,
        ).stdout
        if strip:
            output = output.strip()
        return output
    except subprocess.CalledProcessError:
        return ""


def bytes_to_gigabytes(value: int) -> int:
    return round(value / 1024**3)


def find_file(name: str, path: str) -> Optional[str]:
    for dpath, _, fnames in os.walk(path):
        for fname in fnames:
            if fname == name:
                return os.path.join(dpath, fname)
    return None


def get_executable(names: list[str], paths: list[str]) -> Optional[str]:
    if names is None or paths is None:
        return None
    for name in names:
        for path in paths:
            found = find_file(name, path)
            if found:
                return found
    # Only search for installed packages, if there are no manually compiled binaries
    for name in names:
        exec = shutil.which(name)
        if exec:
            return exec
    return None


def grep(path: str, search: str) -> str:
    try:
        with open(path, "r") as file:
            lines = file.readlines()
            for line in lines:
                if search in line:
                    return line
    except FileNotFoundError:
        logger.log_error(f"File '{path}' not found!")
    return ""


def log_level_converter(log_level: str) -> str:
    if log_level.lower() in ["quiet", "debug", "dev"]:
        return log_level.upper()
    return "INFO"


def resolution_converter(resolution: str) -> tuple[str, str]:
    try:
        width, height = resolution.split("x")
        # Check if width and height are integers but return strings
        return str(int(width)), str(int(height))
    except ValueError:
        raise ValueError(
            "Custom Error", f"'{resolution}' is not of format '<width>x<height>'!"
        )


def is_pi5() -> bool:
    model_path = "/proc/device-tree/model"
    pi5 = grep(model_path, "Raspberry Pi 5")
    cm5 = grep(model_path, "Raspberry Pi Compute Module 5")
    return bool(pi5) or bool(cm5)
