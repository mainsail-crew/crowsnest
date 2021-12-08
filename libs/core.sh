#!/bin/bash

#### Core library

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

## Version of webcamd
function self_version {
    pushd "${BASE_CN_PATH}" &> /dev/null
    git describe --always --tags
    popd &> /dev/null
}

# Init Traps
trap 'shutdown' 1 2 3 15
trap 'err_exit $? $LINENO' ERR

function err_exit {
    if [ "${1}" != "0" ]; then
        log_msg "ERROR: Error ${1} occured on line ${2}"
        log_msg "ERROR: Stopping $(basename "$0")."
        log_msg "Goodbye..."
    fi
    if [ -n "$(jobs -pr)" ]; then
        kill $(jobs -pr)
    fi
    exit 1
}

function shutdown {
    log_msg "Shutdown or Killed by User!"
    log_msg "Please come again :)"
    if [ -n "$(jobs -pr)" ]; then
        kill $(jobs -pr)
    fi
    log_msg "Goodbye..."
    exit 0
}

## Sanity Checks
# Dependency Check
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

# Check for Dependency
function initial_check {
    log_msg "INFO: Checking Dependencys"
    check_dep "logger"
    check_dep "crudini"
    check_dep "ustreamer"
    check_dep "v4l2rtspserver"
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
