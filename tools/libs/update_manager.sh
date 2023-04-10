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

## Funcs
add_update_entry() {
    local moonraker_conf
    moonraker_conf="${CROWSNEST_CONFIG_PATH}/moonraker.conf"
    moonraker_update="${PWD}/resources/moonraker_update.txt"
    if [[ -f "${moonraker_conf}" ]]; then
        if [[ "$(grep -c "crowsnest" "${moonraker_conf}")" != "0" ]]; then
            status_msg "Update Manager entry already exists moonraker.conf ..." "2"
            return 0
        fi
        # make sure no file exist
        if [[ -f "/tmp/moonraker.conf" ]]; then
            sudo rm -f /tmp/moonraker.conf
        fi
        sudo -u "${BASE_USER}" \
        cp "${moonraker_conf}" "${moonraker_conf}.backup" &&
        cat "${moonraker_conf}" "${moonraker_update}" > /tmp/moonraker.conf &&
        cp -rf /tmp/moonraker.conf "${moonraker_conf}"
        if [[ "${CROWSNEST_UNATTENDED}" = "1" ]]; then
            sudo rm -f "${moonraker_conf}.backup"
        fi
        if [[ "$(grep -c "crowsnest" "${moonraker_conf}")" != "0" ]]; then
            status_msg "Adding Crowsnest Update Manager entry to moonraker.conf ... " "0"
            return 0
        else
            status_msg "Adding Crowsnest Update Manager entry to moonraker.conf ... " "1"
        fi
    else
        status_msg "File 'moonraker.conf' does not exist! ..." "2"
    fi
}
