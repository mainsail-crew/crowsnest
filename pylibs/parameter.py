from . import logger

class Parameter:
    def __init__(self, type=str, default=None) -> None:
        self.type = type
        self.set_value(default)

    def set_value(self, value):
        try:
            if value is None:
                self.value = None
            elif self.type == bool:
                if value.lower() == 'true':
                    self.value = True
                elif value.lower() == 'false':
                    self.value = False
                else:
                    logger.log_error(f"{value} is not 'true' or 'false'! Parameter ignored!")
            else:
                self.value = self.type(value)
        except ValueError:
            logger.log_error(f"{value} is not of type {self.type}! Parameter ignored!")
