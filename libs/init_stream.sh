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
    local cams sleep_pid
    # See configparser.sh L#53
    log_msg "Try to start configured Cams / Services..."
    for cams in $(configured_cams); do
        mode="$(get_param "cam ${cams}" mode)"
        case ${mode} in
            mjpg)
                check_section "${cams}"
                run_ustreamer "${cams}" &
                sleep 2 & sleep_pid="$!" ; wait "${sleep_pid}"
            ;;
            rtsp)
                if [ -z "$(pidof rtsp-simple-server)" ]; then
                    run_rtsp &
                    sleep 2 & sleep_pid="$!"; wait "${sleep_pid}"
                else
                    echo "RTSP Server already running ... Skipped." | \
                    log_output "INFO:"
                fi
                run_ffmpeg "${cams}" &
                sleep 8 & sleep_pid="$!"; wait "${sleep_pid}"
            ;;
            webrtc)
                log_msg "Not now implemented"
            ;;
            ?|*)
                unknown_mode_msg
                run_ustreamer "${cams}" &
                sleep 1
            ;;
        esac
    done
    log_msg "... Done!"
    return 0
}
