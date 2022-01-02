#!/usr/bin/env bash
# Crow's Nest
# A multiple Cam and Stream Service for mainsailOS
# Written by Stephan Wendel aka KwadFan <me@stephanwe.de>
# Copyright 2021
# https://github.com/mainsail-crew/crowsnest
# GPL V3
########

# shellcheck enable=require-variable-braces

## disabeld SC2086 for some lines because there we want 'word splitting'

set -e

## Debug
# set -x

# Global Vars
BASE_USER=$(whoami)
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
    echo -e "\tSome Parts of the Installer requires 'root' privileges."
    echo -e "\tYou will be prompted for your 'sudo' password, if needed.\n"
}

function detect_msg {
    echo -e "Found an existing 'webcamd'. This will be removed."
    echo -e "Since we dont use mjpg-streamer it will also removed."
    echo -e "You can use KIAUH for example to reinstall.\n"
}

function goodbye_msg {
    echo -e "\nInstallation complete.\n\tPlease reboot your machine!"
    echo -e "I hope you enjoy crowsnest, GoodBye ..."
}

### Installer

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

### Import config from custompios.
function import_config {
    if [ -f "${HOME}/crowsnest/custompios/crowsnest/config" ]; then
        # shellcheck disable=SC1091
        source custompios/crowsnest/config
    else
        echo -e "${TITLE}\n"
        echo -e "OOPS!\nConfiguration File missing! Exiting..."
        echo -e "Try to git clone a second time please ...\n"
        exit 1
    fi
}

### Detect webcamd.
function detect_existing_webcamd {
    local remove
    if  [ -x "/usr/local/bin/webcamd" ] && [ -d "${HOME}/mjpg-streamer" ]; then
        detect_msg
        read -rp "Do you want to remove existing 'webcamd'? (YES/NO) " remove
        if [ "${remove}" = "YES" ]; then
            echo -en "\nStopping webcamd.service ...\r"
            # sudo systemctl stop webcamd.service &> /dev/null
            echo -e "Stopping webcamd.service ... \t[OK]\r"
            remove_existing_webcamd
        else
            echo -e "\nYou answered '${remove}'! Installation will be aborted..."
            echo -e "GoodBye...\n"
            exit 1
        fi
    fi
}

### Remove existing webcamd
function remove_existing_webcamd {
    if [ -x "/usr/local/bin/webcamd" ]; then
        echo -en "Removing 'webcamd' ...\r"
        sudo rm -f /usr/local/bin/webcamd > /dev/null
        echo -e "Removing 'webcamd' ... \t\t[OK]\r"
    fi
    if [ -d "${HOME}/mjpg-streamer" ]; then
        echo -en "Removing 'mjpg-streamer' ...\r"
        sudo rm -rf "${HOME}"/mjpg-streamer > /dev/null
        echo -e "Removing 'mjpg-streamer' ... \t[OK]\r"
    fi
    if [ -f "/etc/systemd/system/webcamd.service" ]; then
        echo -en "Removing 'webcamd.service' ...\r"
        sudo rm -f /etc/systemd/system/webcamd.service > /dev/null
        echo -e "Removing 'webcamd.service' ... \t[OK]\r"
    fi
    if [ -f "/var/log/webcamd.log" ]; then
        echo -en "Removing 'webcamd.log' ...\r"
        sudo rm -f /var/log/webcamd.log > /dev/null
        sudo rm -f "${HOME}"/klipper_logs/webcamd.log > /dev/null
        echo -e "Removing 'webcamd.log' ... \t[OK]\r"
    fi
    if [ -f "/etc/logrotate.d/webcamd" ]; then
        echo -en "Removing 'webcamd' logrotate...\r"
        sudo rm -f /etc/logrotate.d/webcamd > /dev/null
        echo -e "Removing 'webcamd' logrotate ... \t[OK]\r"
    fi
    echo -e "\nOld 'webcamd' completly removed."
    echo -e "webcam.txt kept,but no longer necessary ..."
}

function install_go {
    local sha256sum
    if [ ! -d /usr/local/go ]; then
        echo -e "Dependency: Go ${CROWSNEST_GOLANG_VERSION} not installed."
        echo -e "Installing Go ${CROWSNEST_GOLANG_VERSION} ..."
        echo -en "Download Go ${CROWSNEST_GOLANG_VERSION} (${CROWSNEST_GOLANG_URL})... \r"
        curl --silent -JLo /tmp/"${CROWSNEST_GOLANG_ARCHIVE}" \
        "${CROWSNEST_GOLANG_URL}${CROWSNEST_GOLANG_ARCHIVE}"
        echo -e "Download Go ${CROWSNEST_GOLANG_VERSION} (${CROWSNEST_GOLANG_URL})... [OK]"
        sha256sum="$(sha256sum /tmp/"${CROWSNEST_GOLANG_ARCHIVE}" | cut -d ' ' -f1)"
        echo -en "Checking sha256sum ...\r"
        if [ "${sha256sum}" = "${CROWSNEST_GOLANG_SHA}" ]; then
            echo -e "Checking sha256sum ... [OK]"
        else
            echo -e "Checking sha256sum ... [FAILED]"
            echo -e "Aborting Install ..."
            echo -e "Goodbye..."
            exit 1
        fi
        sudo tar -C "${CROWSNEST_GOLANG_GO_BIN}" -xf "/tmp/${CROWSNEST_GOLANG_ARCHIVE}"
        echo -en "Setup GOPATH and add 'go' to PATH ...\r"
        if [ ! -f "${HOME}/.gorc" ]; then
            cp file_templates/.gorc "${HOME}"
            echo -e "\n# Add Go Variables to profile\nsource ${HOME}/.gorc\n" >> \
            "${HOME}"/.profile
            # shellcheck disable=SC1091
            source "${HOME}/.profile"
        fi
        echo -e "Setup GOPATH and add to PATH ... [OK]"
    else
        echo -e "$(go version) is already installed ... [skipping]"
    fi
}

function install_crowsnest {
    local template servicefile logrotatefile bin_path webcamd_bin
    bin_path="/usr/local/bin"
    webcamd_bin="${HOME}/crowsnest/webcamd"
    template="${PWD}/sample_configs/${CROWSNEST_DEFAULT_CONF}"
    servicefile="${PWD}/file_templates/webcamd.service"
    logrotatefile="${HOME}/crowsnest/file_templates/logrotate_webcamd"
    echo -e "\nInstall webcamd Service ..."
    ## Install Dependencies
    echo -e "Installing 'crowsnest' Dependencies ..."
    # shellcheck disable=2086
    sudo apt install --yes --no-install-recommends ${CROWSNEST_CROWSNEST_DEPS} > /dev/null
    install_go
    echo -e "Installing 'crowsnest' Dependencies ... [OK]"
    ## Link webcamd to $PATH
    echo -en "Linking webcamd ...\r"
    sudo ln -sf "${webcamd_bin}" "${bin_path}" > /dev/null
    echo -e "Linking webcamd ... [OK]\r"
    ## Copy webcam.conf
    # Make sure not to overwrite existing!
    if [ ! -f "${CROWSNEST_DEFAULT_CONF_DIR}/webcam.conf" ]; then
        echo -en "Copying webcam.conf ...\r"
        sudo -u "${BASE_USER}" cp -rf "${template}" "${CROWSNEST_DEFAULT_CONF_DIR}"/webcam.conf
        echo -e "Copying webcam.conf ... [OK]\r"
    fi
    ## Link webcamd.service
    echo -en "Copying webcamd.service file ...\r"
    sudo cp -rf "${servicefile}" /etc/systemd/system/webcamd.service > /dev/null
    echo -e "Copying webcamd.service file ... [OK]\r"
    ## Link logrotate
    echo -en "Linking logrotate file ...\r"
    sudo cp -rf "${logrotatefile}" /etc/logrotate.d/webcamd
    echo -e "Linking logrotate file ... [OK]\r"
    echo -en "Reload systemd to enable new deamon ...\r"
    sudo systemctl daemon-reload
    echo -e "Reload systemd to enable new daemon ... [OK]"
    echo -en "Enable webcamd.service on boot ...\r"
    sudo systemctl enable webcamd.service
    echo -e "Enable webcamd.service on boot ... [OK]\r"
}

function build_apps {
    echo -e "Build dependend Stream Apps ..."
    echo -e "Installing 'ustreamer' Dependencies ..."
    # shellcheck disable=2086
    sudo apt install --yes --no-install-recommends ${CROWSNEST_USTREAMER_DEPS} > /dev/null
    echo -e "Installing 'ustreamer' Dependencies ... [OK]"
    pushd bin > /dev/null
    make all
    popd > /dev/null
}

function install_raspicam_fix {
    sudo sh -c 'echo "bcm2835-v4l2" >> /etc/modules'
    sudo cp file_templates/bcm2835-v4l2.conf /etc/modprobe.d/
}

#### MAIN
install_cleanup_trap
import_config
welcome_msg
detect_existing_webcamd
echo -e "Running apt update first ..."
sudo apt update
install_crowsnest
build_apps
install_raspicam_fix
goodbye_msg

exit 0
