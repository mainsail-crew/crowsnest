class Parameter:
    def __init__(self, type=str, default=None) -> None:
        self.type = type
        self.set_value(default)

    def set_value(self, value):
        if value is None:
            self.value = None
        elif self.type == 'bool':
            if value.lower() == 'true':
                self.value = True
            elif value.lower() == 'false':
                self.value = False
        else:
            self.value = self.type(value)
