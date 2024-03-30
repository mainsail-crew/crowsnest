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
                    raise ValueError()
            else:
                self.value = self.type(value)
        except ValueError as e:
            message = f"'{value}' is not of type '{self.type.__name__}'!"
            if len(e.args) > 1 and e.args[0] == "Custom Error":
                message = e.args[1]
            message += " Parameter ignored!"
            logger.log_error(message)
