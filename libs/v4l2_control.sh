#!/bin/bash

#### v4l2 control library

#### crowsnest - A webcam Service for multiple Cams and Stream Services.
####
#### Written by Stephan Wendel aka KwadFan <me@stephanwe.de>
#### Copyright 2021
#### https://github.com/mainsail-crew/crowsnest
####
#### This File is distributed under GPLv3
####
#### Description: Configure Cam with v4l2-ctl options
#### ex.: v4l2-ctl -c brightness=100

# shellcheck enable=require-variable-braces

# Exit upon Errors
set -Ee

function v4l2_control {
    v4c_log_msg() {
        log_msg "V4L2 Control: ${1}"
    }

    function main {
        local device v4l2ctl valueless opt_avail
        for cam in $(configured_cams); do
            # get device from cam section
            device="$(get_param "cam ${cam}" device)"
            # get v4l2ctl parameters
            v4l2ctl="$(get_param "cam ${cam}" v4l2ctl)"
            # if not empty do
            if [[ -n "${v4l2ctl}" ]]; then
                # Write configured options to Log
                v4c_log_msg "Device: [cam ${cam}]"
                v4c_log_msg "Options: ${v4l2ctl}"
                # Split options to array
                IFS="," read -ra opt < <(echo "${v4l2ctl}" | tr -d " "); unset IFS
                # loop through options
                for param in "${opt[@]}"; do
                    # parameter available for device
                    # needs || true to prevent script to exit
                    valueless="$(echo "${param}" | cut -d "=" -f1)"
                    opt_avail="$(v4l2-ctl -d "${device}" -L | \
                    grep -c "${valueless}" || true)"
                    if [[ "${opt_avail}" -eq "0" ]]; then
                        v4c_log_msg "Parameter '${param}' not available for '${device}'. Skipped."
                    else
                        v4l2-ctl -d "${device}" -c "${param}" 2> /dev/null ||
                        v4c_log_msg "Failed to set parameter: '${param}' ..."
                    fi
                done
                    if [[ "${CROWSNEST_LOG_LEVEL}" == "debug" ]]; then
                        v4l2-ctl -d "${device}" -L | log_output "v4l2ctl"
                    fi
            else
                v4c_log_msg "No parameters set for [cam ${cam}]. Skipped."
            fi
        done
    }

### MAIN
main
}

function brokenfocus {
    # checks if "focus_absolute" is configured
    # call if_focus_absolute <mycamnameornumber>
    # returns 1 = true, 0 = false
    function if_focus_absolute {
        local cam
        cam="${1}"
        get_param "cam ${cam}" v4l2ctl | grep -c "focus_absolute"
    }

    # checks if device has "focus_absolute"
    # call has_focus_absolute <device>
    # returns 1 if true, 0 if false
    function has_focus_absolute {
        v4l2-ctl -d "${1}" -C "focus_absolute" &> /dev/null \
        && echo "1" || echo "0"
    }

    # call get_conf_value <mycamnameornumber>
    # spits out value from config file
    function get_conf_value {
        local cam conf_val
        local -a params
        cam="${1}"
        conf_val="$(get_param "cam ${cam}" v4l2ctl)"
        if [ -n "${conf_val}" ]; then
            IFS=','; read -ra params <<< "${conf_val}"
            unset IFS
            for i in "${params[@]}"; do
                grep "focus_absolute" <<< "${i}" || true
            done
        fi
    }

    # call get_current_value <device>
    # ex.: get_current_value /dev/video0
    # spits out focus_absolute=20 ( if set to 20 )
    function get_current_value {
        v4l2-ctl -d "${1}" -C "focus_absolute" 2> /dev/null | sed 's/:[[:space:]]/=/'
    }

    # call set_current_value <device> <value>
    # ex.: set_current_value /dev/video0 focus_absolute=30
    function set_focus_absolute {
        local device value
        device="${1}"
        value="${2}"
        v4l2-ctl -d "${device}" -c "${value}"
    }

    function main {
        local cur_val conf_val device
        for cam in $(configured_cams); do
            device="$(get_param "cam ${cam}" device)"
            cur_val="$(get_current_value "${device}")"
            conf_val="$(get_conf_value "${cam}")"
            if [ "$(has_focus_absolute "${device}")" == "1" ] &&
            [ "$(if_focus_absolute "${cam}")" == "1" ] &&
            [ "${cur_val}" != "${conf_val}" ]; then
                detected_broken_dev_msg
                set_focus_absolute "${device}" "${conf_val}"
            fi
            if [[ "${CROWSNEST_LOG_LEVEL}" == "debug" ]] && [[ -n "${cur_val}" ]]; then
                debug_focus_val_msg "$(get_current_value "${device}")"
            fi
        done
    }

### MAIN
main

}

# This function is to set bitrate on raspicams.
# If raspicams set to variable bitrate, they tend to show
# a "block-like" view after reboots
# To prevent that blockyfix should apply constant bitrate befor start of ustreamer
# See https://github.com/mainsail-crew/crowsnest/issues/33
function blockyfix {
    local dev v4l2ctl

    # call set_bitrate <device>
    function set_bitrate {
        v4l2-ctl -d "${1}" -c video_bitrate_mode=1 2> /dev/null
        v4l2-ctl -d "${1}" -c video_bitrate=15000000 2> /dev/null
    }

    for cam in $(configured_cams); do
        dev="$(get_param "cam ${cam}" device)"
        v4l2ctl="$(get_param "cam ${cam}" v4l2ctl)"
        if [ "${dev}" = "$(dev_is_legacy)" ]; then
            if [ -z "${v4l2ctl}" ] ||
            [ "$(grep -c "video_bitrate" <<< "${v4l2ctl}")" == "0" ]; then
                set_bitrate "${dev}"
                blockyfix_msg_1
            fi
        fi
    done
}
