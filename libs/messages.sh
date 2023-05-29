#!/bin/bash

#### message library

#### crowsnest - A webcam Service for multiple Cams and Stream Services.
####
#### Written by Stephan Wendel aka KwadFan <me@stephanwe.de>
#### Copyright 2021
#### https://github.com/mainsail-crew/crowsnest
####
#### This File is distributed under GPLv3
####

# shellcheck enable=require-variable-braces

# Exit upon Errors
set -Ee

## Message Helpers

## core lib
function missing_args_msg {
    echo -e "crowsnest: Missing Arguments!"
    echo -e "\n\tTry: crowsnest -h\n"
}

function wrong_args_msg {
    echo -e "crowsnest: Wrong Arguments!"
    echo -e "\n\tTry: crowsnest -h\n"
}

function help_msg {
    echo -e "crowsnest - webcam deamon\nUsage:"
    echo -e "\t crowsnest [Options]"
    echo -e "\n\t\t-h Prints this help."
    echo -e "\n\t\t-v Prints Version of crowsnest."
    echo -e "\n\t\t-c </path/to/configfile>\n\t\t\tPath to your webcam.conf\n"
}

function deprecated_msg_1 {
    log_msg "Parameter 'streamer' is deprecated!"
    log_msg "Please use mode: [ mjpg | multi ]"
    log_msg "ERROR: Please update your crowsnest.conf! Stopped."
}

function unknown_mode_msg {
    log_msg "WARN: Unknown Mode configured!"
    log_msg "WARN: Using 'mode: mjpg' as fallback!"
}

## v4l2_control lib
function detected_broken_dev_msg {
    log_msg "WARN: Detected 'brokenfocus' device."
    log_msg "INFO: Trying to set to configured Value."
}

# call debug_focus_val_msg <value>
# ex.: debug_focus_val_msg focus_absolute=30
function debug_focus_val_msg {
    log_msg "DEBUG: Value is now: ${1}"
}

## blockyfix
function blockyfix_msg_1 {
    log_msg "INFO: Blockyfix: Setting video_bitrate_mode to constant."
}

function mmal_error_msg {
    log_msg "ERROR: Legacy camera stack enabled!"
    log_msg "INFO: Found mmal device (Legacy cam stack raspicam) ..."
    log_msg "INFO: Please visit https://crowsnest.mainsail.xyz/faq/how-to-setup-a-raspicam for more information"
    log_msg "ERROR: Stopping $(basename "$0")."
    log_msg "Goodbye..."
}

function legacy_stack_msg {
    log_msg "WARN: Detected enabled legacy camera stack"
    log_msg "INFO: If possible, disable it by removing all occurences of 'start_x=1' in '/boot/config.txt'"
    log_msg "INFO: if needed for some reason, DSI screen for ex., ignore this message ..."
}

function no_usable_device_msg {
    log_msg "ERROR: No usable Devices Found. Stopping $(basename "${0}")."
    log_msg "INFO: If there is a USB webcam connected, please check wiring and is supported by v4l2!"
    log_msg "INFO: See https://crowsnest.mainsail.xyz/faq/how-to-use-v4l2-ctl"
    log_msg "INFO: If a Raspicam is connected, please check wiring and take look"
    log_msg "INFO: at https://crowsnest.mainsail.xyz/faq/how-to-setup-a-raspicam"
    log_msg "INFO: for troubleshooting!"
}
