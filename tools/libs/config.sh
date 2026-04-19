#!/usr/bin/env bash

#### crowsnest - A webcam Service for multiple Cams and Stream Services.
####
#### Written by Stephan Wendel aka KwadFan <me@stephanwe.de>
#### Copyright 2021 - 2026
#### Co-authored by Patrick Gehrsitz aka mryel00 <mryel00.github@gmail.com>
#### Copyright 2026 - till today
#### https://github.com/mainsail-crew/crowsnest
####
#### This File is distributed under GPLv3
####

# shellcheck enable=require-variable-braces

# Exit on errors
set -Ee

# Debug
# set -x

import_config() {
    msg "Reading configuration ..."
    ## Source config if present
    if [[ ! -f "${SRC_DIR}/.config" ]]; then
        check_multi_instance
    fi

    if [[ -s "${SRC_DIR}/.config" ]]; then
        msg "User configuration file found ..."
        # shellcheck disable=SC1091
        if source "${SRC_DIR}/.config"; then
            status_msg "Import of user configuration ..." "0"
        else
            status_msg "Import of user configuration ..." "1"
        fi
    fi

    if [[ ! -f "${SRC_DIR}/.config" ]]; then
        msg "No user configuration file found ..."
        [[ -n "${CROWSNEST_CONFIG_PATH}" ]] || CROWSNEST_CONFIG_PATH="/home/${BASE_USER}/printer_data/config"
        [[ -n "${CROWSNEST_LOG_PATH}" ]] || CROWSNEST_LOG_PATH="/home/${BASE_USER}/printer_data/logs"
        [[ -n "${CROWSNEST_ENV_PATH}" ]] || CROWSNEST_ENV_PATH="/home/${BASE_USER}/printer_data/systemd"
        status_msg "Using default configuration ..." "0"
    fi
}
