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
# shellcheck source-path=SCRIPTDIR

# Exit on errors
set -Ee

# Debug
# set -x

## Helper Func
get_avail_mem() {
    grep "MemTotal" /proc/meminfo | awk '{print $2}'
}

set_gpu_mem() {
    local mem_split
    mem_split=""
    ## Determine Ramsize and export MAKEFLAG
    if [[ "$(get_avail_mem)" -le 524288 ]]; then
        mem_split=128
    elif [[ "$(get_avail_mem)" -le 1048576 ]]; then
        mem_split=160
    else
        mem_split=256
    fi
    if [[ "$(is_raspbian)" = "1" ]] && [[ -n "$(command -v raspi-config)" ]]; then
        if sudo raspi-config nonint do_memory_split "${mem_split}" ;then
            status_msg "Trying to set minimum GPU Memory to ${mem_split} MB ..." "0"
        else
            status_msg "Trying to set minimum GPU Memory to ${mem_split} MB ..." "2"
            msg "\t==> Tool 'raspi-config' not found ..."
        fi
    fi
}
