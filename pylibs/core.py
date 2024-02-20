import importlib
import asyncio
import logging
import time
import os

# Dynamically import module
# Requires module to have a load_module() function,
# as well as the same name as the section keyword
def get_module_class(path = '', module_name = ''):
    module_class = None
    try:
        module = importlib.import_module(f'{path}.{module_name}')
        module_class = getattr(module, 'load_module')()
    except (ModuleNotFoundError, AttributeError) as e:
        print('ERROR: '+str(e))
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
        info_log_func = logging.info,
        error_log_func = logging.error,
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
    # Wait for the subprocess to finish
    #await process.wait()

    # Wait for the output handling tasks to finish
    #await stdout_task
    #await stderr_task

def log_debug(msg):
    logging.log(15, msg)
