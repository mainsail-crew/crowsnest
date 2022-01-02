#!/bin/bash

#### v4l2 control library

#### webcamd - A webcam Service for multiple Cams and Stream Services.
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
set -e

function v4l2_control {
    log_msg "V4L2 Control:"

    function main {
        local device v4l2ctl valueless opt_avail
        for cam in $(configured_cams); do
            # get device from cam section
            device="$(get_param "cam ${cam}" device)"
            # get v4l2ctl parameters
            v4l2ctl="$(get_param "cam ${cam}" v4l2ctl)"

            # if not empty do
            if [ -n "${v4l2ctl}" ]; then
                # Write configured options to Log
                log_msg "Device: [cam ${cam}]"
                log_msg "Options: ${v4l2ctl}"
                # Split options to array
                IFS=',' read -ra opt < <(echo "${v4l2ctl}"); unset IFS
                # loop through options
                for param in "${opt[@]}"; do
                    # parameter available for device
                    # needs || true to prevent script to exit
                    valueless="$(echo "${param}" | cut -d "=" -f1)"
                    opt_avail="$(v4l2-ctl -d "${device}" -L | \
                    grep -c "${valueless}" || true)"
                    if [ "${opt_avail}" -eq "0" ]; then
                        log_msg "Parameter '${param}' not available for '${device}'. Skipped."
                    else
                        v4l2-ctl -d "${device}" -c "${param}" 2> /dev/null
                    fi
                done
            else
                log_msg "No parameters set for [cam ${cam}]. Skipped."
            fi
        done
    }

### MAIN
main
}
