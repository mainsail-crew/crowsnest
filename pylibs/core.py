import importlib

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
