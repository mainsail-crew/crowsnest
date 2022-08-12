#!/bin/bash

#### Logging library

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

## Logging
function set_log_path {
    #Workaround sed ~ to BASH VAR $HOME
    CROWSNEST_LOG_PATH=$(get_param "crowsnest" log_path | sed "s#^~#${HOME}#gi")
    declare -g CROWSNEST_LOG_PATH
    #Workaround: Make Dir if not exist
    if [ ! -d "$(dirname "${CROWSNEST_LOG_PATH}")" ]; then
        mkdir -p "$(dirname "${CROWSNEST_LOG_PATH}")"
    fi
}

function init_logging {
    set_log_path
    delete_log
    log_msg "crowsnest - A webcam Service for multiple Cams and Stream Services."
    log_msg "Version: $(self_version)"
    log_msg "Prepare Startup ..."
    print_host
}

function log_level {
    local loglevel
    loglevel="$(get_param crowsnest log_level 2> /dev/null)"
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
    del_log="$(get_param "crowsnest" delete_log 2> /dev/null)"
    if [ "${del_log}" = "true" ]; then
        rm -rf "${CROWSNEST_LOG_PATH}"
    fi
}

function log_msg {
    local msg prefix
    msg="${1}"
    prefix="$(date +'[%D %T]') crowsnest:"
    echo -e "${prefix} ${msg}" | tr -s ' ' | tee -a "${CROWSNEST_LOG_PATH}" 2>&1
    echo -e "${msg}" | logger -t crowsnest
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
            echo "${line//^--/ustreamer}" | logger -t crowsnest
        fi
    done
}

function print_cfg {
    local prefix
    prefix="\t\t"
    log_msg "INFO: Print Configfile: '${CROWSNEST_CFG}'"
    (sed '/^#.*/d;/./,$!d' | cut -d'#' -f1) < "${CROWSNEST_CFG}" | \
    while read -r line; do
        log_msg "${prefix}${line}"
    done
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

function print_host {
    local disksize generic_model memtotal sbc_model
    generic_model="$(grep "model name" /proc/cpuinfo | cut -d':' -f2 | awk NR==1)"
    sbc_model="$(grep "Model" /proc/cpuinfo | cut -d':' -f2)"
    memtotal="$(grep "MemTotal:" /proc/meminfo | awk '{print $2" "$3}')"
    disksize="$(LC_ALL=C df -h / | awk 'NR==2 {print $4" / "$2}')"
    ## print only if not log_level: quiet
    if [ "$(log_level)" != "quiet" ]; then
        log_msg "INFO: Host information:"
        ## OS Infos
        ## OS Version
        if [ -f /etc/os-release ]; then
            log_msg "Host Info: Distribution: $(grep "PRETTY" /etc/os-release | \
            cut -d '=' -f2 | sed 's/^"//;s/"$//')"
        fi
        ## Release Version of MainsailOS (if file present)
        if [ -f /etc/mainsailos-release ]; then
            log_msg "Host Info: Release: $(cat /etc/mainsailos-release)"
        fi
        ## Kernel version
        log_msg "Host Info: Kernel: $(uname -s) $(uname -rm)"
        ## Host Machine Infos
        ## Host model
        if [ -n "${sbc_model}" ]; then
            log_msg "Host Info: Model: ${sbc_model}"
        fi
        if [ -n "${generic_model}" ] &&
        [ -z "${sbc_model}" ]; then
            log_msg "Host Info: Model: ${generic_model}"
        fi
        ## CPU count
        log_msg "Host Info: Available CPU Cores: $(nproc)"
        ## Avail mem
        log_msg "Host Info: Available Memory: ${memtotal}"
        ## Avail disk size
        log_msg "Host Info: Diskspace (avail. / total): ${disksize}"
    fi
}

function debug_msg {
    local prefix
    prefix="Develop -- DEBUG:"
    while read -r msg; do
        log_msg "${prefix} ${msg}"
        echo -e "${msg}" | logger -t crowsnest
    done <<< "${1}"
}
