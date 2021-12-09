#!/bin/bash

#### Init Stream library

#### webcamd - A webcam Service for multiple Cams and Stream Services.
####
#### written by Stephan Wendel aka KwadFan
#### Copyright 2021
#### https://github.com/mainsail-crew/crowsnest
####
#### This File is distributed under GPLv3
####

# Exit upon Errors
set -e

## Start Stream Service
# sleep to prevent cpu cycle spikes
function construct_streamer {
    local stream_server cams
    cams=($(configured_cams))
    log_msg "Try to start configured Cams / Services..."
    for (( i=0; i<"${#cams[@]}"; i++ )); do
        stream_server="$(get_param "cam ${cams[$i]}" streamer 2> /dev/null)"
        if [ "${stream_server}" == "ustreamer" ]; then
            run_ustreamer "${cams[$i]}" &
            sleep 8 & sleep_pid="$!"
            wait "${sleep_pid}"
        elif [ "${stream_server}" == "rtsp" ]; then
            run_rtsp "${cams[$i]}" &
            sleep 8 & sleep_pid="$!"
            wait "${sleep_pid}"
        else
            log_msg "ERROR: Missing 'streamer' parameter in [cam ${cams[$i]}]. Skipping."
        fi
    done
    log_msg "... Done!"
}
