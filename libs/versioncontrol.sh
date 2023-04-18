#!/bin/bash

#### version control library

#### crowsnest - A webcam Service for multiple Cams and Stream Services.
####
#### Written by Stephan Wendel aka KwadFan <me@stephanwe.de>
#### Copyright 2021
#### https://github.com/mainsail-crew/crowsnest
####
#### This File is distributed under GPLv3
####
#### Description: Checks Versions of Streamer and ffmpeg
####

# shellcheck enable=require-variable-braces

# Exit upon Errors
set -Ee

versioncontrol() {

    vc_log_msg() {
        log_msg "Version Control: ${1}"
    }

    get_ustreamer_version() {
        local cur_ver avail_ver
        pushd "${BASE_CN_PATH}"/bin/ustreamer &> /dev/null || exit 1
            avail_ver="$(git describe --tags --always)"
            cur_ver="v$("${PWD}"/ustreamer -v)"
            if [[ "${cur_ver}" == "${avail_ver}" ]]; then
                vc_log_msg "ustreamer is up to date. (${cur_ver})"
            fi
            if [[ "${cur_ver}" != "${avail_ver}" ]]; then
                vc_log_msg "ustreamer new version available: ${avail_ver} (${cur_ver})."
            fi
        popd &> /dev/null || exit 1
    }


    # Camera Streamer has no version Output yet
    get_ayucamstream_version() {
        local cur_ver avail_ver
        if [[ "$(is_raspberry_pi)" = "1" ]] && [[ "$(is_ubuntu_arm)" = "0" ]]; then
            pushd "${BASE_CN_PATH}"/bin/camera-streamer &> /dev/null || exit 1
                avail_ver="($(git describe --tags --always))"
                cur_ver="$("${PWD}"/camera-streamer --version | tr -d " ")"
                if [ "${cur_ver}" == "${avail_ver}" ]; then
                    vc_log_msg "camera-streamer is up to date. (${cur_ver})"
                fi
                if [ "${cur_ver}" != "${avail_ver}" ]; then
                    vc_log_msg "camera-streamer new version available: ${avail_ver} (${cur_ver})."
                fi
            popd &> /dev/null || exit 1
        fi
    }

    ### MAIN
    function main {
        if [[ "${CROWSNEST_LOG_LEVEL}" != "quiet" ]]; then
            get_ustreamer_version
            if [[ "$(is_raspberry_pi)" = "1" ]]; then
                get_ayucamstream_version
            fi
        fi
    }

    main
    return
}
