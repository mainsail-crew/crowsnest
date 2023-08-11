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
    local file_trace func_trace line_trace
    read -r LINE FUNC FILE < <(caller 0)
    func_trace="${FUNC}"
    file_trace="$(basename "${FILE}")"
    line_trace="${LINE}"
    if [ "${1}" != "0" ]; then
        log_msg "ERROR: Error ${1} occured on line ${line_trace}"
        log_msg "==> Error occured in file: ${file_trace} -> ${func_trace}"
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
    if [[ -z "${dep}" ]]; then
        log_msg "Dependency: '${1}' not found. Exiting!"
        exit 1
    else
        log_msg "Dependency: '${1}' found in ${dep}."
    fi
}

function check_apps {
    local cstreamer ustreamer
    ustreamer="bin/ustreamer/ustreamer"
    cstreamer="bin/camera-streamer/camera-streamer"

    if [[ -x "${BASE_CN_PATH}/${ustreamer}" ]]; then
        log_msg "Dependency: '${ustreamer##*/}' found in ${ustreamer}."
    else
        log_msg "Dependency: '${ustreamer##*/}' not found. Exiting!"
        exit 1
    fi

    ## Avoid dependency check if non rpi sbc
    if [[ "$(is_raspberry_pi)" = "1" ]] && [[ "$(is_ubuntu_arm)" = "0" ]]; then
        if [[ -x "${BASE_CN_PATH}/${cstreamer}" ]]; then
            log_msg "Dependency: '${cstreamer##*/}' found in ${cstreamer}."
        else
            log_msg "Dependency: '${cstreamer##*/}' not found. Exiting!"
            exit 1
        fi
    fi
}

# Check all needed Dependencies
# If pass print your set configfile to log.
# print_cfg, see libs/logging.sh L#75
# pint_cams, see libs/logging.sh L#84
function initial_check {
    log_msg "INFO: Checking Dependencies"
    check_dep "crudini"
    check_dep "find"
    check_dep "xargs"
    check_apps
    versioncontrol
    # print cfg if ! "${CROWSNEST_LOG_LEVEL}": quiet
    if [ -z "$(check_cfg "${CROWSNEST_CFG}")" ]; then
        if [[ "${CROWSNEST_LOG_LEVEL}" != "quiet" ]]; then
            print_cfg
        fi
    fi
    log_msg "INFO: Detect available Devices"
    print_cams
    return
}
