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

### Crowsnest Dependencies
PKGLIST="git crudini bsdutils findutils v4l-utils curl"
### Ustreamer Dependencies
PKGLIST="${PKGLIST} build-essential libevent-dev libjpeg-dev libbsd-dev"
