# Crow's Nest
A multiple Cam and Stream Service for mainsailOS

# Developer Documentation

The folder 'crowsnest' is made to add to your existing CustomPIOS Structure.

Please take a closer look to the 'config' File and set it up to your specific needs.
This is pretty much self explantory.

At least you have to configure:

    CROWSNEST_DEFAULT_CONF="mainsail_default.conf"
This takes a conf file from the 'sample_configs' called mainsail_default.conf
and put it to 

    CROWSNEST_DEFAULT_CONF_DIR="/home/${BASE_USER}/klipper_config"
the folder you configured above.\
Please feel free to Pull Request your config!
I will add them.

Last but not least:

    CROWSNEST_MOONRAKER_SUPPORT="y"
this will tell the module to add the content of moonraker_update.txt to your
moonraker.conf\
_Please take note, that moonraker.conf has to be in your CROWSNEST_DEFAULT_CONF_DIR !_

Finally add crowsnest to your config!
As example:

    export MODULES="base(network,(klipper,moonraker,mainsail,crowsnest))"

Make sure it is barely the last one, because it mangles cmake quiet often
unfortunatly.\
 This isn't my fault, more the "pickynese" behavior of
mjpg-streamer and v4l2rtspserver :)