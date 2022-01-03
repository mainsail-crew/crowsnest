#!/bin/bash

#### message library

#### webcamd - A webcam Service for multiple Cams and Stream Services.
####
#### Written by Stephan Wendel aka KwadFan <me@stephanwe.de>
#### Copyright 2021
#### https://github.com/mainsail-crew/crowsnest
####
#### This File is distributed under GPLv3
####

# shellcheck enable=require-variable-braces

# Exit upon Errors
set -e

## Message Helpers
function missing_args_msg {
    echo -e "webcamd: Missing Arguments!"
    echo -e "\n\tTry: webcamd -h\n"
}

function wrong_args_msg {
    echo -e "webcamd: Wrong Arguments!"
    echo -e "\n\tTry: webcamd -h\n"
}

function help_msg {
    echo -e "webcamd - webcam deamon\nUsage:"
    echo -e "\t webcamd [Options]"
    echo -e "\n\t\t-h Prints this help."
    echo -e "\n\t\t-v Prints Version of webcamd."
    echo -e "\n\t\t-c </path/to/configfile>\n\t\t\tPath to your webcam.conf\n"
}

function deprecated_msg_1 {
    log_msg "Parameter 'streamer' is deprecated!"
    log_msg "Please use mode: (mjpg/webrtc)"
    log_msg "ERROR: Please update your webcam.conf! Stopped."
}
