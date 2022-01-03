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

function prepare_rtsp {
    local cam_section rtsp_bin ffmpeg_bin
    local start_param
    cam_section="${1}"
    rtsp_bin="bin/rtsp-simple-server/rtsp-simple-server"
    ffmpeg_bin="$(whereis ffmpeg | awk '{print $2}')"
    device="$(get_param "cam ${cam_section}" device)"
    port=$(get_param "cam ${cam_section}" port)
    resolution=$(get_param "cam ${cam_section}" resolution)
    fps=$(get_param "cam ${cam_section}" max_fps)
    split_res="$(echo "${resolution}" | \
        awk -F 'x' '{print "-W "$1 " -H "$2}')"
    start_param=(
                    -I 0.0.0.0 -P "${port}" "${split_res}" -F "${fps}" \
                    "${device}"
                )
    log_msg "Starting rtsp-simple-server with Device ${device} ..."
    echo "Parameters: ${start_param[*]}" | \
    log_output "rtsp-simple-server [cam ${cam_section}]"
    # Start ffmpeg
    echo "${start_param[*]}" | xargs "${rtsp_bin}" 2>&1 | \
    log_output "v4l2rtspserver [cam ${cam_section}]"
    log_msg "ERROR: Start of v4l2rtspserver [cam ${cam_section}] failed!"
}

function run_rtsp {
    local rtsp_bin config
    rtsp_bin="bin/rtsp-simple-server/rtsp-simple-server"
    config="${BASE_CN_PATH}/file_templates/crowsnest-rtsp.yml"
    log_msg "Starting rtsp-simple-server with config ${config} ..."
    echo "Config file: ${config}" | \
    log_output "rtsp-simple-server [cam ${cam_section}]"
    # Start rtsp-simple-server
    "${rtsp_bin}" "${config}" 2>&1 | \
    log_output "v4l2rtspserver [cam ${cam_section}]"
    # Should not be seen else failed.
    log_msg "ERROR: Start of rtsp-simple failed!"
    echo "Config file: ${config}" | \
    log_output "rtsp-simple-server [cam ${cam_section}]"
}
