class Resolution():
    def __init__(self, value:str) -> None:
        try:
            self.width, self.height = value.split('x')
        except ValueError:
            # logger.log_error(f"{value} is not of format '<width>x<height>'! Parameter ignored!")
            raise ValueError("Custom Error", f"'{value}' is not of format '<width>x<height>'! "
                             "Parameter ignored!")

    def __str__(self) -> str:
        return 'x'.join([self.width, self.height])
