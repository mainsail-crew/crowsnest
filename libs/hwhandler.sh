#!/bin/bash

#### Hardware Handling library

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

### Detect Hardware
function detect_avail_cams {
    local avail realpath
    avail="$(find /dev/v4l/by-id/ 2> /dev/null | sort -n | sed '1d;1~2d')"
    if [ -d "/dev/v4l/by-id/" ]; then
        echo "${avail}" | while read -r i; do
            realpath=$(readlink -e "${i}")
            log_msg "${i} -> ${realpath}"
            if [ "$(log_level)" != "quiet" ]; then
                list_cam_formats "${i}"
            fi
        done
    else
        log_msg "ERROR: No usable Cameras found. Exiting."
        exit 1
    fi
}

# Used for "verbose" and "debug" logging in logging.sh
function list_cam_formats {
    local device
    device="${1}"
    formats="$(v4l2-ctl -d "${device}" --list-formats-ext | sed '1,3d')"
    log_msg "Supported Formats:"
    echo "${formats}" | while read -r i; do
        log_msg "\t\t${i}"
    done
}

# Determine connected "raspicam" device
function detect_raspicam {
    local avail
    if [ -f /proc/device-tree/model ] &&
    grep -q "Raspberry" /proc/device-tree/model; then
        avail="$(vcgencmd get_camera | awk -F '=' '{ print $3 }')"
    else
        avail="0"
    fi
    echo "${avail}"
}

function dev_is_raspicam {
    v4l2-ctl --list-devices |  grep -A1 -e 'mmal' | \
    awk 'NR==2 {print $1}'
}

# Determine if cam has H.264 Hardware encoder
# call detect_h264 <nameornumber> ex.: detect_h264 foobar
# returns 1 = true / 0 = false ( numbers are strings! not int!)
function detect_h264 {
    local dev
    dev="$(get_param "cam ${1}" device)"
    v4l2-ctl -d "${dev}" --list-formats-ext | grep -c "[hH]264"
}

# Determine if cam has MJPEG Hardware encoder
# call detect_mjpeg <nameornumber> ex.: detect_mjpeg foobar
# returns 1 = true / 0 = false ( numbers are strings! not int!)
function detect_mjpeg {
    local dev
    dev="$(get_param "cam ${1}" device)"
    v4l2-ctl -d "${dev}" --list-formats-ext | grep -c "Motion-JPEG, compressed"
}
