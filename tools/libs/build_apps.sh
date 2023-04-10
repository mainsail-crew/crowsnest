#!/usr/bin/env bash

#### crowsnest - A webcam Service for multiple Cams and Stream Services.
####
#### Written by Stephan Wendel aka KwadFan <me@stephanwe.de>
#### Copyright 2021 - till today
#### https://github.com/mainsail-crew/crowsnest
####
#### This File is distributed under GPLv3
####

# shellcheck enable=require-variable-braces

# Exit on errors
set -Ee

# Debug
# set -x

clone_ustreamer() {
    ## remove bin/ustreamer if exist
    if [[ -d bin/ustreamer ]]; then
        rm -rf bin/ustreamer
    fi
    sudo -u "${BASE_USER}" \
    git clone "${CROWSNEST_USTREAMER_REPO_SHIP}" \
    -b "${CROWSNEST_USTREAMER_REPO_BRANCH}" \
    --depth=1 --single-branch bin/ustreamer
}

clone_cstreamer() {
    ## remove bin/ustreamer if exist
    if [[ -d bin/camera-streamer ]]; then
        rm -rf bin/camera-streamer
    fi
    sudo -u "${BASE_USER}" \
    git clone "${CROWSNEST_CAMERA_STREAMER_REPO_SHIP}" --recursive \
    -b "${CROWSNEST_CAMERA_STREAMER_REPO_BRANCH}" \
    --depth=1 --single-branch bin/camera-streamer
}

build_apps() {
    msg "Build dependend Stream Apps ..."
    msg "Cloning ustreamer repository ..."
    clone_ustreamer
    ## Detect Image build for Raspberrys
    if [[ "$(is_raspbian)" = "1" ]]; then
        msg "Cloning camera-streamer repository ..."
        clone_cstreamer
    fi
    if [[ "$(is_raspbian)" = "0" ]]; then
        msg "Install of camera-streamer skipped, only supported on Raspberry SBC's! ... "
    fi
    sudo -u "${BASE_USER}" "${PWD}"/bin/build.sh --build
}
