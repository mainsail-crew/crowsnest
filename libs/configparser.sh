#!/bin/bash

#### Configparser library

#### webcamd - A webcam Service for multiple Cams and Stream Services.
####
#### written by Stephan Wendel aka KwadFan
#### Copyright 2021
#### https://github.com/mainsail-crew/crowsnest
####
#### This File is distributed under GPLv3
####

# Exit upon Errors
set -e

# Read Configuration File
# call get_param section param
# spits out raw value
function get_param {
    local cfg
    local section
    local param
    cfg="${WEBCAMD_CFG}"
    section="${1}"
    param="${2}"
    crudini --get "${cfg}" "${section}" "${param}" | \
    sed 's/\#.*//;s/[[:space:]]*$//'
} 2> /dev/null

# Check for existing file
function check_cfg {
    if [ ! -r "${1}" ]; then
        log_msg "ERROR: No Configuration File found. Exiting!"
        exit 1
    fi
}

function check_section {
    local section param must_exist missing
    section="cam ${1}"
    # Ignore missing custom flags
    param="$(crudini --existing=param --get "${WEBCAMD_CFG}" "${section}" \
    2> /dev/null | sed '/custom_flags/d')"
    must_exist="streamer port device resolution max_fps"
    missing="$(echo "${param}" "${must_exist}" | \
    tr ' ' '\n' | sort | uniq -u)"
    if [ -n "${missing}" ]; then
        log_msg "ERROR: Parameter ${missing} not found in \
        Section [${section}]. Start skipped!"
        exit 1
    else
        log_msg "INFO: Configuration of Section [${section}] looks good. \
        Continue..."
    fi
}

## Spits out all [cam <nameornumber>] configured sections
function configured_cams {
    local cam_count cfg
    cfg="${WEBCAMD_CFG}"
    cams="$(crudini --existing=file --get "${cfg}" | \
    sed '/webcamd/d;s/cam//')"
    echo "${cams}"
}
