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

### Crowsnest Dependencies
PKGLIST="git crudini bsdutils findutils v4l-utils curl"
### Ustreamer Dependencies
PKGLIST="${PKGLIST} build-essential libevent-dev libjpeg-dev libbsd-dev pkg-config"
### Camera-Streamer Dependencies
### If you change something below, also have a look at tools/libs/core.sh->shallow_cs_dependencies_check
PKGLIST="${PKGLIST} cmake libavformat-dev libavutil-dev libavcodec-dev libcamera-dev libcamera-apps-lite"
PKGLIST="${PKGLIST} liblivemedia-dev pkg-config xxd build-essential cmake libssl-dev"
