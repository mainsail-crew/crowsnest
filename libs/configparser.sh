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

# shellcheck enable=requires-variable-braces

# Exit upon Errors
set -e

# Read Configuration File
# call get_param section param
# spits out raw value
function get_param {
    local cfg section param
    cfg="${WEBCAMD_CFG}"
    section="${1}"
    param="${2}"
    crudini --get "${cfg}" "${section}" "${param}" | \
    sed 's/\#.*//;s/[[:space:]]*$//' || echo ""
}

# Check for existing file
# Exit with error if not exist
function check_cfg {
    if [ ! -r "${1}" ]; then
        log_msg "ERROR: No Configuration File found. Exiting!"
        exit 1
    fi
}

## Spits out all [cam <nameornumber>] configured sections
function configured_cams {
    local cams cfg
    cfg="${WEBCAMD_CFG}"
    for i in $(crudini --existing=file --get "${cfg}" | \
    sed '/webcamd/d;s/cam//'); do
        cams+=("${i}")
    done
    echo "${cams[@]}"
}

# Checks [cam <nameornumber>] if all needed configuration sections are present
# call check_section <nameornumber> ex.: check_section foobar
function check_section {
    local section param must_exist missing
    section="cam ${1}"
    # Ignore missing custom flags
    param="$(crudini --existing=param --get "${WEBCAMD_CFG}" "${section}" \
    2> /dev/null | sed '/custom_flags/d;/v4l2ctl/d')"
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
