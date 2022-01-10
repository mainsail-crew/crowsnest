#!/usr/bin/env bash
#### webcamd - A webcam Service for multiple Cams and Stream Services.
####
#### Written by Stephan Wendel aka KwadFan <me@stephanwe.de>
#### Copyright 2021
#### https://github.com/mainsail-crew/crowsnest
####
#### This File is distributed under GPLv3
####

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
# Welcome Message
function welcome_msg {
    echo -e "${TITLE}\n"
    echo -e "\tYou will be prompted for your 'sudo' password, if needed."
    echo -e "\tSome Parts of the Updater requires 'root' privileges."
    # Dirty hack to gain root permissions
    sudo echo -e "\n"
}

# Goodbye Message
function goodbye_msg {
    echo -e "\nInstallation complete.\n"
    echo -e "\tIn case something was updated:\n\tPlease reboot your machine!"
    echo -e "I hope you enjoy crowsnest, GoodBye ..."
}

# No longer needed Message
function remove_message {
    echo -e "Found ${1}, remove because it is not longer needed."
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

# Helper funcs
function stop_webcamd {
    if [ "$(sudo systemctl is-active webcamd.service)" = "active" ]; then
        sudo systemctl stop webcamd &> /dev/null
    fi
}

function start_webcamd {
    if [ "$(sudo systemctl is-active webcamd.service)" = "active" ]; then
        sudo systemctl start webcamd &> /dev/null
    fi
}

function daemon_reload {
    echo -en "Reload systemd to enable new deamon ...\r"
    sudo systemctl daemon-reload &> /dev/null
    echo -e "Reload systemd to enable new daemon ... [OK]"
}

function diff_files {
    diff "${1}" "${2}"
}

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

# Copy Files funcs
function copy_service {
    local servicefile origin
    origin="/etc/systemd/system/webcamd.service"
    servicefile="${HOME}/crowsnest/file_templates/webcamd.service"
    if [ -n "$(diff_files "${origin}" "${servicefile}")" ]; then
        echo -en "Copying webcamd.service file ...\r"
        sudo cp -rf "${servicefile}" "${origin}" > /dev/null
        echo -e "Copying webcamd.service file ... [OK]\r"
        daemon_reload
    else
        echo -e "No update of '${origin}' required."
    fi
}

function copy_logrotate {
    local logrotatefile origin
    origin="/etc/logrotate.d/webcamd"
    logrotatefile="${HOME}/crowsnest/file_templates/logrotate_webcamd"
    if [ -n "$(diff_files "${origin}" "${logrotatefile}")" ]; then
        echo -en "Copying logrotate file ...\r"
        sudo cp -rf "${logrotatefile}" "${origin}" > /dev/null
        echo -e "Copying logrotate file ... [OK]\r"
    else
        echo -e "No update of '${origin}' required."
    fi
}

function copy_raspicam_fix {
    local logrotatefile origin
    origin="/etc/modprobe.d/bcm2835-v4l2.conf"
    logrotatefile="${HOME}/crowsnest/file_templates/bcm2835-v4l2.conf"
    if [ ! -f "${origin}" ]; then
        echo -en "Copying bcm2835-v4l2.conf file ...\r"
        sudo cp -rf "${logrotatefile}" "${origin}" > /dev/null
        echo -e "Copying bcm2835-v4l2.conf file ... [OK]\r"
    else
        if [ -n "$(diff_files "${origin}" "${logrotatefile}")" ]; then
            echo -en "Copying bcm2835-v4l2.conf file ...\r"
            sudo cp -rf "${logrotatefile}" "${origin}" > /dev/null
            echo -e "Copying bcm2835-v4l2.conf file ... [OK]\r"
        else
            echo -e "No update of '${origin}' required."
        fi
    fi
}

# Uninstall funcs
function uninstall_v4l2rtsp {
    local bin_path v4l2rtsp_dir
    bin_path="/usr/local/bin/v4l2rtspserver"
    v4l2rtsp_dir="${HOME}/v4l2rtspserver"
    if [ -d "${v4l2rtsp_dir}" ]; then
        remove_message "v4l2rtspserver"
        echo -en "Uninstalling 'v4l2rtspserver' ...\r"
        if [ -x "${bin_path}" ]; then
            sudo rm -f "${bin_path}"
        fi
        sudo rm -rf "${v4l2rtsp_dir}"
        echo -e "Uninstalling 'v4l2rtspserver' ... [OK]\r"
    fi
}

function uninstall_ustreamer {
    local bin_path ustreamer_dir
    bin_path="/usr/local/bin/ustreamer"
    ustreamer_dir="${HOME}/ustreamer"
    if [ -d "${v4l2rtsp_dir}" ]; then
        remove_message "ustreamer"
        echo -en "Uninstalling '${HOME}/ustreamer' ...\r"
        if [ -x "${bin_path}" ]; then
            sudo rm -f "${bin_path}"
        fi
        sudo rm -rf "${ustreamer_dir}"
        echo -e "Uninstalling '${HOME}/ustreamer' ... [OK]\r"
    fi
}
# Install funcs
function install_go {
    echo -e "\nDependency Check: Go 1.17.5"
    if [ "$(go version | awk '{print $3}')" != "go1.17.5" ]; then
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

# Build Apps
function build_apps {
    echo -e "\nDependency Check: Check for compiled Apps ..."
    if [ ! -x "bin/ustreamer/src/ustreamer.bin" ] \
    && [ ! -x "bin/rtsp-simple-server/rtsp-simple-server" ] \
    && [ ! -x "bin/RTSPtoWebRTC/rtsp2webrtc" ]; then
        echo -e "Build dependend Stream Apps ..."
        echo -e "Installing 'ustreamer' Dependencies ..."
        # shellcheck disable=2086
        sudo apt install --yes --no-install-recommends ${CROWSNEST_USTREAMER_DEPS} > /dev/null
        echo -e "Installing 'ustreamer' Dependencies ... [OK]"
        pushd bin > /dev/null
        make all
        popd > /dev/null
    else
        echo -e "All Apps are present ... [skipped]"
    fi
}



#### MAIN
install_cleanup_trap
import_config
welcome_msg
stop_webcamd
uninstall_ustreamer
uninstall_v4l2rtsp
copy_service
copy_logrotate
copy_raspicam_fix
install_go
build_apps
start_webcamd
goodbye_msg

exit 0
