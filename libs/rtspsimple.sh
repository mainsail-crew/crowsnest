#!/bin/bash

#### ustreamer library

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

run_rtsp() {
    local cams
    cams="${1}"
    if [[ -z "$(pidof rtsp-simple-server)" ]]; then
        run_rtsp_srv &
    fi
    for instance in ${cams} ; do
        run_ffmpeg "${instance}" &
    done
}


run_ffmpeg() {
    local cam_section ffmpeg_bin start_param
    cam_section="${1}"
    ffmpeg_bin="$(whereis ffmpeg | awk '{print $2}')"
    dev="$(get_param "cam ${cam_section}" device)"
    # Construct start_param
    start_param=( -nostdin -hide_banner -f video4linux2 )
    if [[ "$(detect_h264 "${cam_section}")" = "1" ]]; then
        start_param+=( -input_format h264 -pix_fmt h264 )
    else
        start_param+=( -input_format yuyv422 )
    fi
    start_param+=(
        -video_size "$(get_param "cam ${cam_section}" resolution)"
        -framerate "$(get_param "cam ${cam_section}" max_fps)"
        -i "${dev}"
    )
    if [[ "$(detect_h264 "${cam_section}")" -eq 0 ]] &&
        [[ "$(check_omx)" -eq 1 ]]; then
            start_param+=( -c:v h264_omx -b:v 8M )
    else
        start_param+=( -c:v copy )
    fi
    start_param+=(-f rtsp -rtsp_transport tcp rtsp://localhost:8554/"${cam_section}" )
    # Log start_param
    log_msg "Starting ffmpeg (rtsp stream source) with Device ${dev} ..."
    echo "Parameters: ${start_param[*]}" | \
    log_output "ffmpeg (rtsp stream source) [cam ${cam_section}]"
    # Start ffmpeg
    echo "${start_param[*]}" | xargs "${ffmpeg_bin}" 2>&1 | \
    log_output "ffmpeg (rtsp stream source) [cam ${cam_section}]"
    # Should not be seen else failed.
    log_msg "ERROR: Start of ffmpeg (rtsp stream source) [cam ${cam_section}] failed!"
}

run_rtsp_srv() {
    local rtsp_bin config
    rtsp_bin="${BASE_CN_PATH}/bin/rtsp-simple-server/rtsp-simple-server"
    config="${BASE_CN_PATH}/resources/crowsnest-rtsp.yml"
    log_msg "Starting rtsp-simple-server with config ${config} ..."
    echo "Config file: ${config}" | \
    log_output "rtsp-simple-server [INFO]"
    # Start rtsp-simple-server
    # Have to use this dirty bash hack to get output to logfile.
    "${rtsp_bin}" "${config}" &> >(log_output "rtsp-simple-server")
    # Should not be seen else failed.
    log_msg "ERROR: Start of rtsp-simple failed!"
    echo "Config file: ${config}" | \
    log_output "rtsp-simple-server [ERROR]"
}
