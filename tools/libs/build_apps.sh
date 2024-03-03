#!/usr/bin/env bash

#### crowsnest - A webcam Service for multiple Cams and Stream Services.
####
#### Written by Stephan Wendel aka KwadFan <me@stephanwe.de>
#### Copyright 2021 - 2023
#### Co-authored by Patrick Gehrsitz aka mryel00 <mryel00.github@gmail.com>
#### Copyright 2023 - till today
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
    git clone "${CROWSNEST_CAMERA_STREAMER_REPO_SHIP}" \
    --recurse-submodules --shallow-submodules \
    -b "${CROWSNEST_CAMERA_STREAMER_REPO_BRANCH}" \
    --depth=1 --single-branch bin/camera-streamer
}

build_apps() {
    export CN_INSTALL_CS
    sudo -E -u "${BASE_USER}" "${PWD}"/bin/build.sh --reclone
    sudo -u "${BASE_USER}" "${PWD}"/bin/build.sh --build
}
