#!/bin/bash

#### Logging library

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
set -Ee

## Logging
function set_log_path {
    #Workaround sed ~ to BASH VAR $HOME
    CROWSNEST_LOG_PATH=$(get_param webcamd log_path | sed "s#^~#${HOME}#gi")
    declare -g CROWSNEST_LOG_PATH
    #Workaround: Make Dir if not exist
    if [ ! -d "$(dirname "${CROWSNEST_LOG_PATH}")" ]; then
        mkdir -p "$(dirname "${CROWSNEST_LOG_PATH}")"
    fi
}

function init_logging {
    set_log_path
    delete_log
    log_msg "webcamd - A webcam Service for multiple Cams and Stream Services."
    log_msg "Version: $(self_version)"
    log_msg "Prepare Startup ..."
}

function log_level {
    local loglevel
    loglevel="$(get_param webcamd log_level 2> /dev/null)"
    # Set default log_level to quiet
    if [ -z "${loglevel}" ] || [[ "${loglevel}" != @(quiet|verbose|debug) ]];
    then
        echo "quiet"
    else
        echo "${loglevel}"
    fi
}

function delete_log {
    local del_log
    del_log="$(get_param "webcamd" delete_log 2> /dev/null)"
    if [ "${del_log}" = "true" ]; then
        rm -rf "${CROWSNEST_LOG_PATH}"
    fi
}

function log_msg {
    local msg prefix
    msg="${1}"
    prefix="$(date +'[%D %T]') webcamd:"
    echo -e "${prefix} ${msg}" | tr -s ' ' >> "${CROWSNEST_LOG_PATH}" 2>&1
    echo -e "${msg}" | logger -t webcamd
}

#call '| log_output "<prefix>"'
function log_output {
    local prefix
    prefix="DEBUG: ${1}"
    while read -r line; do
        if [ "$(log_level)" == "debug" ]; then
            log_msg "${prefix}: ${line}"
        fi
        if [ -n "${line}" ]; then
            # needed to prettify ustreamers output
            echo "${line//^--/ustreamer}" | logger -t webcamd
        fi
    done
}

function print_cfg {
    local prefix
    prefix="\t\t"
    log_msg "INFO: Print Configfile: '${WEBCAMD_CFG}'"
    while read -r line; do
        log_msg "${prefix}${line}"
    done < "${WEBCAMD_CFG}"
}

function print_cams {
    local csi raspicam total v4l
    v4l="$(find /dev/v4l/by-id/ -iname "*index0" 2> /dev/null | wc -l)"
    csi="$(find /dev/v4l/by-path/ -iname "*csi*index0" 2> /dev/null | wc -l)"
    total="$((v4l+$(detect_raspicam)+csi))"
    if [ "${total}" -eq 0 ]; then
        log_msg "ERROR: No usable Devices Found. Stopping $(basename "${0}")."
        exit 1
    else
        log_msg "INFO: Found ${total} total available Device(s)"
    fi
    if [ "$(detect_raspicam)" -ne 0 ]; then
        raspicam="$(v4l2-ctl --list-devices |  grep -A1 -e 'mmal' | \
        awk 'NR==2 {print $1}')"
        log_msg "Detected 'Raspicam' Device -> ${raspicam}"
        if [ ! "$(log_level)" = "quiet" ]; then
            list_cam_formats "${raspicam}"
            list_cam_v4l2ctrls "${raspicam}"
        fi
    fi
    if [ -d "/dev/v4l/by-id/" ]; then
        detect_avail_cams
    fi
    if [ -d "/dev/v4l/by-path" ]; then
        detect_avail_csi
    fi
}

function debug_msg {
    local prefix
    prefix="Develop -- DEBUG:"
    while read -r msg; do
        log_msg "${prefix} ${msg}"
        echo -e "${msg}" | logger -t webcamd
    done <<< "${1}"
}
