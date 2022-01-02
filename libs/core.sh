#!/bin/bash

#### Core library

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

## Version of webcamd
function self_version {
    pushd "${BASE_CN_PATH}" &> /dev/null
    git describe --always --tags
    popd &> /dev/null
}

# Init Traps
trap 'shutdown' 1 2 3 15
trap 'err_exit $? $LINENO' ERR

# Behavior of traps
# log_msg, see libs/logging.sh L#46

# Print Error Code and Line to Log
# and kill running jobs
function err_exit {
    if [ "${1}" != "0" ]; then
        log_msg "ERROR: Error ${1} occured on line ${2}"
        log_msg "ERROR: Stopping $(basename "$0")."
        log_msg "Goodbye..."
    fi
    if [ -n "$(jobs -pr)" ]; then
        jobs -pr | while IFS='' read -r job_id; do
            kill "${job_id}"
        done
    fi
    exit 1
}

# Print Goodbye Message
# and kill running jobs
function shutdown {
    log_msg "Shutdown or Killed by User!"
    log_msg "Please come again :)"
    if [ -n "$(jobs -pr)" ]; then
        jobs -pr | while IFS='' read -r job_id; do
            kill "${job_id}"
        done
    fi
    log_msg "Goodbye..."
    exit 0
}

## Sanity Checks
# Dependency Check
# call check_dep <programm>, ex.: check_dep vim
function check_dep {
    local dep
    dep="$(whereis "${1}" | awk '{print $2}')"
    if [ -z "${dep}" ]; then
        log_msg "Dependency: '${1}' not found. Exiting!"
        exit 1
    else
        log_msg "Dependency: '${1}' found in ${dep}."
    fi
}

function check_apps {
    local paths
    paths=( \
        "bin/ustreamer/ustreamer" \
        "bin/rtsp-simple-server/rtsp-simple-server" \
        "bin/RTSPtoWebRTC/rtsp2webrtc"
        )
    for chk in "${paths[@]}"; do
        if [ -x "${BASE_CN_PATH}/${chk}" ]; then
            log_msg "Dependency: '$(cut -d '/' -f3 < "${chk}")' not found. Exiting!"
        else
            log_msg "Dependency: '$(cut -d '/' -f3 <<< "${chk}")' found in ${chk}."
        fi
    done
}

# Check all needed Dependencies
# If pass print your set configfile to log.
# print_cfg, see libs/logging.sh L#75
# pint_cams, see libs/logging.sh L#84
function initial_check {
    log_msg "INFO: Checking Dependencys"
    check_dep "crudini"
    check_dep "find"
    check_dep "logger"
    check_dep "xargs"
    check_apps
    # check_dep "rtsp-simple-server" # Stay for later use.
    if [ -z "$(check_cfg "${WEBCAMD_CFG}")" ]; then
        if [ "$(log_level)" != "quiet" ]; then
            print_cfg
        fi
    fi
    # in systemd show always config file
    logger -t webcamd -f "${WEBCAMD_CFG}"
    log_msg "INFO: Detect available Cameras"
    print_cams
}
