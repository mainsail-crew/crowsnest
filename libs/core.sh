#!/bin/bash

#### Core library

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

## Version of crowsnest
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
    paths=(
        bin/ustreamer/ustreamer
        bin/rtsp-simple-server/rtsp-simple-server
        )
    for chk in "${paths[@]}"; do
        if [ -x "${BASE_CN_PATH}/${chk}" ]; then
            log_msg "Dependency: '$(echo "${chk}" | cut -d '/' -f3)' found in ${chk}."
        else
            log_msg "Dependency: '$(echo "${chk}" | cut -d '/' -f3)' not found. Exiting!"
            exit 1
        fi
    done
}

# checks availability of OpenMax IL feature on host and in apps.
# 0 = false / 1 = true
function check_omx {
    if [ -d "/opt/vc/include" ] &&
    [ ! "$(ffmpeg -hide_banner -buildconf | grep -c 'omx')" = "0" ] &&
    [ "$("${BASE_CN_PATH}"/bin/ustreamer/ustreamer --features | grep -c '\+ WITH_OMX')" = "1" ]; then
        echo "1"
    else
        echo "0"
    fi
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
    check_dep "ffmpeg"
    check_apps
    versioncontrol
    # print cfg if ! log_level: quiet
    if [ -z "$(check_cfg "${CROWSNEST_CFG}")" ]; then
        if [ "$(log_level)" != "quiet" ]; then
            print_cfg
        fi
    fi
    # in systemd show always config file
    logger -t crowsnest -f "${CROWSNEST_CFG}"
    log_msg "INFO: Detect available Devices"
    print_cams
}
