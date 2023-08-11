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

### Disable SC2317 due Trap usage
# shellcheck disable=SC2317

# Exit on errors
set -Ee

# Debug
# set -x


TITLE="\e[31mcrowsnest\e[0m - A webcam daemon for multiple cams and stream services."

### Messages
msg() {
    echo -e "${1}"
}

status_msg() {
    local msg status
    msg="${1}"
    status="${2}"
    echo -en "${msg}\r"
    if [[ "${status}" == "0" ]]; then
        echo -e "${msg} [\e[32mOK\e[0m]"
    fi
    if [[ "${status}" == "1" ]]; then
        echo -e "${msg} [\e[31mFAILED\e[0m]"
        error_msg
        exit 1
    fi
    if [[ "${status}" == "2" ]]; then
        echo -e "${msg} [\e[33mSKIPPED\e[0m]"
    fi
}

not_as_root_msg() {
    msg "\n\tPlease do NOT run this script as root!\n"
    msg "\tLogin in as a regular user and run with '\e[32msudo make install\e[0m'\n\n"
}

need_sudo_msg() {
    msg "\n\tYou need to run this script with sudo privileges!"
    msg "\tPlease try '\e[32msudo make install\e[0m'\n\nExiting..."
}

not_supported_msg() {
    msg "\nDebian 10 (buster) has reached end of life.\n"
    msg "Therefore, crowsnest has also ended support for it.\n"
    msg "Please upgrade to a supported OS release,"
    msg "we are sorry for the inconvenience.\n"
}

welcome_msg() {
    msg "${TITLE}\n"
    msg "\t\e[34mAhoy!\e[0m"
    msg "\tThank you for installing crowsnest ;)"
    msg "\tThis will take a while ... "
    msg "\tPlease reboot after the installation has finished.\n"
    sleep 1
}

config_msg() {
    msg "\nConfig file not found!\n\tUsing defaults ..."
    msg "\tThis uses paths located in 'printer_data' of your home folder."
}

goodbye_msg() {
    msg "\nInstallation \e[32msuccessful\e[0m.\n"
    msg "\t\e[33mReboot your machine for the changes to take effect!\e[0m\n"
}

unattended_success_msg() {
    msg "\nInstallation \e[32msuccessful\e[0m.\n"
}

error_msg() {
    msg "Something went wrong!\nPlease copy the latest output, head over to\n"
    msg "\thttps://discord.gg/mainsail\n"
    msg "and open a ticket in #supportforum..."
}
