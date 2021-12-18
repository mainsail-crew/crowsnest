#!/usr/bin/env bash
# Crow's Nest
# A multiple Cam and Stream Service for mainsailOS
# Written by Stephan Wendel aka KwadFan
# Copyright 2021
# https://github.com/mainsail-crew/crowsnest
# GPL V3
#
# patcher.sh - copies new templates to ist destinations.
#
########

# shellcheck enable=requires-variable-braces

set -e

## Debug
# set -x

# Global Vars
TITLE="crowsnest - A Webcam Daemon for Raspberry Pi OS"

### Non root
if [ ${UID} == '0' ]; then
    echo -e "DO NOT RUN THIS SCRIPT AS ROOT!\nExiting..."
    exit 1
fi

### noninteractive Check
if [ -z "${DEBIAN_FRONTEND}" ]; then
    export DEBIAN_FRONTEND=noninteractive
fi

### Functions

### Messages
### Welcome Message
function welcome_msg {
    echo -e "${TITLE}\n"
    echo -e "\tYou will be prompted for your 'sudo' password, if needed.\n"
    echo -e "\tSome Parts of the Installer requires 'root' privileges."

}


function goodbye_msg {
    echo -e "\nInstallation complete.\n\tPlease reboot your machine!"
    echo -e "I hope you enjoy crowsnest, GoodBye ..."
}

### General
## These two functions are reused from custompios common.sh
## Credits to guysoft!
## https://github.com/guysoft/CustomPiOS

function install_cleanup_trap() {
    # kills all child processes of the current process on SIGINT or SIGTERM
    trap 'cleanup' SIGINT SIGTERM
}

function cleanup() {
    # make sure that all child processed die when we die
    echo -e "Killed by user ...\r\nGoodBye ...\r"
    # shellcheck disable=2046
    [ -n "$(jobs -pr)" ] && kill $(jobs -pr) && sleep 5 && kill -9 $(jobs -pr)
}
##

function err_exit {
    if [ "${1}" != "0" ]; then
        echo -e "ERROR: Error ${1} occured on line ${2}"
        echo -e "ERROR: Stopping $(basename "$0")."
        echo -e "Goodbye..."
    fi
    # shellcheck disable=2046
    [ -n "$(jobs -pr)" ] && kill $(jobs -pr) && sleep 5 && kill -9 $(jobs -pr)
    exit 1
}

### Init ERR Trap
trap 'err_exit $? $LINENO' ERR


function stop_webcamd {
    if [ "$(sudo systemctl is-active webcamd.service)" = "active" ]; then
        sudo systemctl stop webcamd
    fi
}

function diff_files {
    diff -s "${1}" "${2}"
}

function copy_service {
    local servicefile template
    template="/etc/systemd/system/webcamd.service"
    servicefile="${HOME}/crowsnest/file_templates/webcamd.service"
    if [ -n "$(diff_files "${template}" "${servicefile}")" ]; then
        echo -en "Copying webcamd.service file ...\r"
        sudo cp -rf "${servicefile}" "${template}" > /dev/null
        echo -e "Copying webcamd.service file ... [OK]\r"
    else
        echo -e "No update of 'webcamd.service' required."
    fi
}

function copy_logrotate {
    local logrotatefile template
    template="/etc/logrotate.d/webcamd"
    logrotatefile="${HOME}/crowsnest/file_templates/logrotate_webcamd"
    if [ -n "$(diff_files "${template}" "${logrotatefile}")" ]; then
        echo -en "Copying logrotate file ...\r"
        sudo cp -rf "${logrotatefile}" "${template}" > /dev/null
        echo -e "Copying logrotate file ... [OK]\r"
    else
        echo -e "No update of 'logrotate/webcamd' required."
    fi
}

function daemon_reload {
    echo -en "Reload systemd to enable new deamon ...\r"
    sudo systemctl daemon-reload
    echo -e "Reload systemd to enable new daemon ... [OK]"
}









#### MAIN
install_cleanup_trap
welcome_msg
stop_webcamd
copy_service
copy_logrotate
goodbye_msg

exit 0
