#!/usr/bin/python3

import importlib
import asyncio
import subprocess
import shutil
import os

from . import logger, v4l2

# Dynamically import component
# Requires module to have a load_component() function,
# as well as the same name as the section keyword
def load_component(component: str,
                   name: str,
                   path='pylibs.components'):
    module_class = None
    try:
        component = importlib.import_module(f'{path}.{component}')
        module_class = getattr(component, 'load_component')(name)
    except (ModuleNotFoundError, AttributeError) as e:
        logger.log_error(f"Failed to load module '{component}' from '{path}'")
    return module_class

async def log_subprocess_output(stream, log_func, line_prefix = ''):
    line = await stream.readline()
    while line:
        l = line_prefix
        l += line.decode('utf-8').strip()
        log_func(l)
        line = await stream.readline()

async def execute_command(
        command: str,
        info_log_func = logger.log_debug,
        error_log_func = logger.log_error,
        info_log_pre = '',
        error_log_pre = ''):

    process = await asyncio.create_subprocess_shell(
        command,
        stdout=asyncio.subprocess.PIPE,
        stderr=asyncio.subprocess.PIPE
    )

    stdout_task = asyncio.create_task(
        log_subprocess_output(
            process.stdout,
            info_log_func,
            info_log_pre
        )
    )
    stderr_task = asyncio.create_task(
        log_subprocess_output(
            process.stderr,
            error_log_func,
            error_log_pre
        )
    )

    return process, stdout_task, stderr_task

def execute_shell_command(command: str, strip: bool = True) -> str:
    try:
        output = subprocess.check_output(command, shell=True).decode('utf-8')
        if strip:
            output = output.strip()
        return output
    except subprocess.CalledProcessError as e:
        return ''

def bytes_to_gigabytes(value: int) -> int:
    return round(value / 1024**3)

def find_file(name: str, path: str) -> str:
    for dpath, _, fnames in os.walk(path):
        for fname in fnames:
            if fname == name:
                return os.path.join(dpath, fname)
    return None

def get_executable(names: list[str], paths: list[str]) -> str:
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
        with open(path, 'r') as file:
            lines = file.readlines()
            for line in lines:
                if search in line:
                    return line
    except FileNotFoundError:
        logger.log_error(f"File '{path}' not found!")    
    return ''
