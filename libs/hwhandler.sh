#!/bin/bash

#### Hardware Handling library

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

### Detect Hardware
detect_avail_cams() {
    local avail realpath
    avail="$(find /dev/v4l/by-id/ -iname "*index0" 2> /dev/null)"
    count="$(echo "${avail}" | wc -l)"
    if [[ -d "/dev/v4l/by-id/" ]] &&
    [[ -n "${avail}" ]]; then
        log_msg "INFO: Found ${count} available v4l2 (UVC) camera(s)"
        echo "${avail}" | while read -r v4l; do
            realpath=$(readlink -e "${v4l}")
            log_msg "${v4l} -> ${realpath}"
            if [[ "${CROWSNEST_LOG_LEVEL}" != "quiet" ]]; then
                list_cam_formats "${v4l}"
                list_cam_v4l2ctrls "${v4l}"
            fi
        done
    else
        log_msg "INFO: No usable Cameras found."
    fi
}

## Used for "verbose" and "debug" logging in logging.sh
list_cam_formats() {
    local device prefix
    device="${1}"
    prefix="$(date +'[%D %T]') crowsnest:"
    log_msg "Supported Formats:"
    while read -r i; do
        printf "%s\t\t%s\n" "${prefix}" "${i}" >> "${CROWSNEST_LOG_PATH}"
    done < <(v4l2-ctl -d "${device}" --list-formats-ext | sed '1,3d')
}

list_cam_v4l2ctrls() {
    local device prefix
    device="${1}"
    prefix="$(date +'[%D %T]') crowsnest:"
    log_msg "Supported Controls:"
    while read -r i; do
        printf "%s\t\t%s\n" "${prefix}" "${i}" >> "${CROWSNEST_LOG_PATH}"
    done < <(v4l2-ctl -d "${device}" --list-ctrls-menus)
}

## Determine connected libcamera (CSI) device
detect_libcamera() {
    local avail
    if [[ "$(is_raspberry_pi)" = "1" ]] &&
    [[ -x "$(command -v libcamera-hello)" ]]; then
        avail="$(libcamera-hello --list-cameras | sed '/^\[.*\].*/d' | awk 'NR==1 {print $1}')"
        if [[ "${avail}" = "Available" ]]; then
            echo "1"
        else
            echo "0"
        fi
    else
        echo "0"
    fi
}

## Spit /base/soc path for libcamera device
get_libcamera_path() {
    if [[ "$(is_raspberry_pi)" = "1" ]] &&
    [[ -x "$(command -v libcamera-hello)" ]]; then
        libcamera-hello --list-cameras | sed '1,2d' \
        | grep "\(/base/*\)" | cut -d"(" -f2 | tr -d '$)'
    fi
}

# Determine connected "legacy" device
function detect_legacy {
    local avail
    if [[ -f /proc/device-tree/model ]] &&
    grep -q "Raspberry" /proc/device-tree/model; then
        avail="$(vcgencmd get_camera | awk -F '=' '{ print $3 }' | cut -d',' -f1)"
    else
        avail="0"
    fi
    echo "${avail}"
}

function dev_is_legacy {
    v4l2-ctl --list-devices |  grep -A1 -e 'mmal' | \
    awk 'NR==2 {print $1}'
}

## Determine if cam has H.264 Hardware encoder
## call detect_h264 <nameornumber> ex.: detect_h264 foobar
## returns 1 = true / 0 = false ( numbers are strings! not int!)
detect_h264() {
    local dev
    dev="$(get_param "cam ${1}" device)"
    v4l2-ctl -d "${dev}" --list-formats-ext | grep -c "[hH]264"
}

## Determine if cam has MJPEG Hardware encoder
## call detect_mjpeg <nameornumber> ex.: detect_mjpeg foobar
## returns 1 = true / 0 = false ( numbers are strings! not int!)
detect_mjpeg() {
    local dev
    dev="$(get_param "cam ${1}" device)"
    v4l2-ctl -d "${dev}" --list-formats-ext | grep -c "Motion-JPEG, compressed"
}

## Check if device is raspberry sbc
is_raspberry_pi() {
    if [[ -f /proc/device-tree/model ]] &&
    grep -q "Raspberry" /proc/device-tree/model; then
        echo "1"
    else
        echo "0"
    fi
}

is_ubuntu_arm() {
    if [[ "$(is_raspberry_pi)" = "1" ]] &&
    grep -q "ubuntu" /etc/os-release; then
        echo "1"
    else
        echo "0"
    fi
}
