#!/bin/bash

#### ustreamer library

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


function run_ustreamer {
    local cam_section ustreamer_bin device port resolution fps custom
    local raspicam start_param wwwroot
    cam_section="${1}"
    ustreamer_bin="${BASE_CN_PATH}/bin/ustreamer/ustreamer"
    device="$(get_param "cam ${cam_section}" device)"
    port=$(get_param "cam ${cam_section}" port)
    resolution=$(get_param "cam ${cam_section}" resolution)
    fps=$(get_param "cam ${cam_section}" max_fps)
    custom="$(get_param "cam ${cam_section}" custom_flags 2> /dev/null)"
    raspicam="$(v4l2-ctl --list-devices |  grep -A1 -e 'mmal' | \
    awk 'NR==2 {print $1}')"
    wwwroot="${BASE_CN_PATH}/ustreamer-www"
    #Raspicam Workaround
    if [ "${device}" == "${raspicam}" ]; then
        start_param=(
                    --host 127.0.0.1 -p "${port}" -m MJPEG --device-timeout=5
                    --buffers=3 -r "${resolution}" -f "${fps}" --allow-origin=\*
                    --static "${wwwroot}"
                    )
    else
        start_param=(
                    -d "${device}" -r "${resolution}" -f "${fps}"
                    --host 127.0.0.1 -p "${port}" --allow-origin=\*
                    --device-timeout=2 --static "${wwwroot}"
                    )
    fi
    # Custom Flag Handling
    if [ -n "${custom}" ]; then
        start_param+=("${custom}")
    fi
    log_msg "Starting ustreamer with Device ${device} ..."
    echo "Parameters: ${start_param[*]}" | \
    log_output "ustreamer [cam ${cam_section}]"
    # Ustreamer is designed to run even if the device is not ready or readable.
    # I dont like that! ustreamer has to exit if Cam isnt there.
    if [ -e "${device}" ]; then
        echo "${start_param[*]}" | xargs "${ustreamer_bin}" 2>&1 | \
        log_output "ustreamer [cam ${cam_section}]"
    else
        log_msg "ERROR: Start of ustreamer [cam ${cam_section}] failed!"
    fi
    return
}
