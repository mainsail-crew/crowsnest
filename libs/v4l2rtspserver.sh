#!/bin/bash

#### ustreamer library

#### webcamd - A webcam Service for multiple Cams and Stream Services.
####
#### written by Stephan Wendel aka KwadFan
#### Copyright 2021
#### https://github.com/mainsail-crew/crowsnest
####
#### This File is distributed under GPLv3
####

# shellcheck enable=require-variable-braces

# Exit upon Errors
set -e

function run_rtsp {
    local cam_section rtsp_bin device port resolution fps custom
    local start_param
    cam_section="${1}"
    rtsp_bin="$(whereis v4l2rtspserver | awk '{print $2}')"
    device="$(get_param "cam ${cam_section}" device)"
    port=$(get_param "cam ${cam_section}" port)
    resolution=$(get_param "cam ${cam_section}" resolution)
    fps=$(get_param "cam ${cam_section}" max_fps)
    custom="$(get_param "cam ${cam_section}" custom_flags 2> /dev/null)"
    check_section "${cam_section}"
    split_res="$(echo "${resolution}" | \
        awk -F 'x' '{print "-W "$1 " -H "$2}')"
    start_param=(
                    -I 0.0.0.0 -P "${port}" "${split_res}" -F "${fps}" \
                    "${device}"
                )
    # Custom Flag Handling
    if [ -n "${custom}" ]; then
        start_param+=("${custom}")
    fi
    log_msg "Starting v4l2rtspserver with Device ${device} ..."
    echo "Parameters: ${start_param[*]}" | \
    log_output "v4l2rtspserver [cam ${cam_section}]"

    echo "${start_param[*]}" | xargs "${rtsp_bin}" 2>&1 | \
    log_output "v4l2rtspserver [cam ${cam_section}]"
    log_msg "ERROR: Start of v4l2rtspserver [cam ${cam_section}] failed!"
}
