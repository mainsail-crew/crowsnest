class CN_Parameter:
    def __init__(self, name, type, default_value=None) -> None:
        self.name = name
        self.default_value = default_value
        self.type = type
        
        # Parameter is required if no default value is specified
        self.required = self.default_value == None
