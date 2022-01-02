#!/bin/bash

#### Init Stream library

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

## Start Stream Service
# sleep to prevent cpu cycle spikes
function construct_streamer {
    local stream_server
    log_msg "Try to start configured Cams / Services..."
    for i in $(configured_cams); do
        stream_server="$(get_param "cam ${i}" streamer 2> /dev/null)"
        if [ "${stream_server}" == "ustreamer" ]; then
            run_ustreamer "${i}" &
            sleep 8 & sleep_pid="$!"
            wait "${sleep_pid}"
        elif [ "${stream_server}" == "rtsp" ]; then
            run_rtsp "${i}" &
            sleep 8 & sleep_pid="$!"
            wait "${sleep_pid}"
        else
            log_msg "ERROR: Missing 'streamer' parameter in [cam ${i}]. Skipping."
        fi
    done
    log_msg "... Done!"
}
