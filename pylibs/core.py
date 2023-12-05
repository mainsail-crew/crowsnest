import importlib
import asyncio
import logging
import time

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

async def log_subprocess_output(stream, log_func):
    while True:
        line = await stream.readline()
        if not line:
            time.sleep(0.05)
            continue
        #line = line.decode('utf-8').strip()
        log_func(line.decode().strip())

async def execute_command(command: str):
    process = await asyncio.create_subprocess_shell(
        command,
        stdout=asyncio.subprocess.PIPE,
        stderr=asyncio.subprocess.PIPE
    )

    stdout_task = asyncio.create_task(log_subprocess_output(process.stdout, logging.info))
    stderr_task = asyncio.create_task(log_subprocess_output(process.stderr, logging.error))

    return process, stdout_task, stderr_task
    # Wait for the subprocess to finish
    #await process.wait()

    # Wait for the output handling tasks to finish
    #await stdout_task
    #await stderr_task
