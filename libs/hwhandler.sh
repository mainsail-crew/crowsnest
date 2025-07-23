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
    if [[ -d "/dev/v4l/by-id/" ]] && [[ -n "${avail}" ]]; then
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

## Detect libcamera package
libcamera_installed() {
    if [[ -x "$(command -v libcamera-hello)" ]] ||
    [[ -x "$(command -v rpicam-hello)" ]]; then
        echo "1"
    else
        echo "0"
    fi
}

## List libcamera (CSI) device
list_libcameras() {
    if [[ -x "$(command -v libcamera-hello)" ]]; then
        libcamera-hello --list-cameras
    else
        rpicam-hello --list-cameras
    fi
}

## Determine connected libcamera (CSI) device
detect_libcamera() {
    local avail
    if [[ "$(is_raspberry_pi)" = "1" ]] &&
    [[ "$(libcamera_installed)" = "1" ]]; then
        avail="$(list_libcameras | grep -c "Available" || echo "0")"
        if [[ "${avail}" = "1" ]]; then
            get_libcamera_path | wc -l
        else
            echo "0"
        fi
    else
        echo "0"
    fi
}

## Split /base/soc path for libcamera device
get_libcamera_path() {
    list_libcameras | sed '1,2d' \
    | grep "\(/base/*\)" | cut -d"(" -f2 | tr -d '$)'
}

# print libcamera resolutions
list_picam_resolution() {
    local prefix
    prefix="$(date +'[%D %T]') crowsnest:"
    log_msg "'libcamera' device(s) resolution(s) :"
    while IFS= read -r i; do
        printf "%s\t\t%s\n" "${prefix}" "${i}" >> "${CROWSNEST_LOG_PATH}"
    done < <(libcamera-hello --list-cameras | sed '1,2d;s/Modes:/Colorspace:/')
}

get_libcamera_controls() {
    local ust_bin flags
    flags=( --camera-type=libcamera --camera-list_options )
    ust_bin="${BASE_CN_PATH}/bin/camera-streamer/camera-streamer"
    if [[ -x "${ust_bin}" ]]; then
        "${ust_bin}" "${flags[@]}" --camera-path="$(get_libcamera_path)" 2> /dev/null | \
        sed 's/device//g;/^SNAPSHOT/q' | sed '/^SNAPSHOT/d' | \
        sed '/^CAMERA/d;/- property/d' | sed '/camera-streamer Version:/d' | \
        sed 's/- available option: //g' | sed '/^$/d;' | \
        sed 's/([0-9]*[a-z,0-9]\, /(/g' | sed '/type=7/d;/type=4/d;/type=Rectangle/d' | \
        sed 's/type=1/bool/g;s/type=3/int/g;s/type=5/float/g' | sed 's/type=//g;' | \
        sed 's/\[/min=/g;s/\.\./ max=/g;s/\]$//g'
    else
        log_msg "WARN: 'libcamera' device option can not be displayed, because"
        log_msg "WARN: camera-streamer is not installed"
    fi
}

list_picam_controls() {
    local prefix
    prefix="$(date +'[%D %T]') crowsnest:"
    log_msg "'libcamera' device controls :"
    while IFS= read -r i; do
        if [[ ! "${i}" =~ "INFO" ]]; then
            printf "%s\t\t%s\n" "${prefix}" "${i}" >>"${CROWSNEST_LOG_PATH}"
        fi
    done < <(get_libcamera_controls)
    # blank line workaround
    log_msg ""
}

# Determine connected "legacy" device
function detect_legacy {
    local avail
    if [[ "$(is_raspberry_pi)" = "1" ]] &&
    command -v vcgencmd &> /dev/null; then
        if vcgencmd get_camera &> /dev/null; then
            avail="$( vcgencmd get_camera | awk -F '=' '{ print $3 }' | cut -d',' -f1)"
        fi
    fi
    echo "${avail:-0}"
}

function dev_is_legacy {
    v4l2-ctl --list-devices | grep -A1 -e 'mmal' | \
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

## Helper funcs
. "${BASE_CN_PATH}/libs/helper_fn.sh"
