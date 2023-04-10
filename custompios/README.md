# Crow's Nest

A multiple Cam and Stream Service for mainsailOS

# Developer Documentation

The folder 'crowsnest' is made to add to your existing CustomPIOS Structure.

If you are not already familiar with this, copy 'crowsnest' folder to

    /src/modules

## Configuration

Please take a closer look to the 'config' File and set it up to your specific needs.
This is pretty much self explantory.

At least you have to configure:

    CROWSNEST_DEFAULT_CONF="resources/crowsnest.conf"

This takes a conf file from the 'sample_configs' called mainsail_default.conf
and put it to

    CROWSNEST_CONFIG_PATH="/home/${BASE_USER}/printer_data/config"

the folder you configured above.\
Please feel free to Pull Request your config!
I will add them.

Last but not least:

    CROWSNEST_ADD_CROWSNEST_MOONRAKER="1"

this will tell the module to add the content of moonraker*update.txt to your
moonraker.conf\
\_Please take note, that moonraker.conf has to be in your CROWSNEST_DEFAULT_CONF_DIR !*

Finally add crowsnest to your config!
As example:

    export MODULES="base(network,raspicam(klipper,moonraker,mainsail,crowsnest))"
