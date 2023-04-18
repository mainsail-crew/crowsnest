#!/bin/bash

#### Configparser library

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

# Read Configuration File
# call get_param section param
# spits out raw value
function get_param {
    local cfg section param
    cfg="${CROWSNEST_CFG}"
    section="${1}"
    param="${2}"
    crudini --get "${cfg}" "${section}" "${param}" 2> /dev/null | \
    sed 's/\#.*//;s/[[:space:]]*$//'
    return
}

# Check for existing file
# Exit with error if not exist
function check_cfg {
    if [ ! -r "${1}" ]; then
        log_msg "ERROR: No Configuration File found. Exiting!"
        exit 1
    else
        return 0
    fi
}

## Spits out all [cam <nameornumber>] configured sections
function configured_cams {
    local cams cfg
    cfg="${CROWSNEST_CFG}"
    for i in $(crudini --existing=file --get "${cfg}" | \
    sed '/crowsnest/d;s/cam//'); do
        cams+=("${i}")
    done
    echo "${cams[@]}"
    return
}

# Checks [cam <nameornumber>] if all needed configuration sections are present
# call check_section <nameornumber> ex.: check_section foobar
function check_section {
    local section exist param
    local -a must_exist missing
    section="cam ${1}"
    # Ignore missing custom flags
    exist="$(crudini --existing=param --get "${CROWSNEST_CFG}" "${section}" \
    2> /dev/null | sed '/custom_flags/d;/v4l2ctl/d')"
    for i in ${exist}; do
        param+=("${i}")
    done
    # Stop on deprecated conf
    for i in "${param[@]}"; do
        if [ "${i}" = "streamer" ]; then
            deprecated_msg_1
            exit 1
        fi
    done
    must_exist=(mode port device resolution max_fps)
    missing=()
    for i in "${must_exist[@]}"; do
        if [[ -z "$(get_param "${section}" "${i}")" ]]; then
            missing+=("${i}")
        fi
    done

    if [[ "${#missing[@]}" != "0" ]]; then
        for param in "${missing[@]}"; do
            log_msg "ERROR: Parameter ${param} not found in Section [${section}]."
        done
        log_msg "ERROR: Please check your configuration!"
        exit 1
    fi
    if [[ "${#missing[@]}" == "0" ]]; then
        log_msg "INFO: Configuration of Section [${section}] looks good. Continue ..."
    fi
    return
}
