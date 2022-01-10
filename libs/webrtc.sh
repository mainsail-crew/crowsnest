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

# Use Port 8085
RTC_PORT="8085"

function run_webrtc {
    generate_config
    if [ -z "$(pidof rtsp2webrtc)" ]; then
    run_srv &
    fi
    sleep 2
}

function generate_config {
    local pt url head stream cfg tmp cnf_cm
    pt="${RTC_PORT}"
    url="rtsp://localhost:8554"
    cfg="${BASE_CN_PATH}/bin/RTSPtoWebRTC/config.json"
    tmp="/tmp/config.json"
    # convert configured_cams to real array
    for cc in $(configured_cams); do
        cnf_cm+=( "${cc}" )
    done
    # Remove existing tmp file
    if [ -f "${tmp}" ]; then
        rm -f /tmp/config.json
    fi
    # Generate config.json
    head[0]='{\n  "server": {'
    head[1]="\n    \"http_port\": \"0.0.0.0:${pt}\","
    head[2]='\n    "ice_servers": ["stun:stun.l.google.com:19302"],'
    head[3]='\n    "ice_username": "",'
    head[4]='\n    "ice_credential": ""\n  },\n  "streams": {'
    echo -e "${head[*]}" > "${tmp}"
    for i in "${cnf_cm[@]}"; do
        c=$((${c}+1))
        stream[0]="    \"${i}\": {"
        stream[1]="\n      \"on_demand\": false,"
        stream[2]="\n      \"disable_audio\": true,"
        stream[3]="\n      \"url\": \"${url}/${i}\""
        if [ "${c}" -eq "${#cnf_cm[@]}" ]; then
            stream[4]="\n    }"
        else
            stream[4]="\n    },"
        fi
        echo -e "${stream[*]}" >> "${tmp}"
    done
    echo -e "  }\n}" >> "${tmp}"
    # Check if it needs to be updated
    cp "${tmp}" "${cfg}"
    return
}

function run_srv {
    local pt rtc_bin
    pt="${RTC_PORT}"
    rtc_bin="${BASE_CN_PATH}/bin/RTSPtoWebRTC/"
    # Log start_param
    log_msg "Starting RTSPtoWebRTC Server ..."
    # Start rtsp2webrtc
    cd "${rtc_bin}"
    # Have to use this dirty bash hack to get output to logfile.
    echo "-listen 0.0.0.0:${pt}" | xargs "./rtsp2webrtc" &> >(log_output "RTSPtoWebRTC")
    # Should not be seen else failed.
    log_msg "ERROR: Start of RTSPtoWebRTC server failed!"
}
