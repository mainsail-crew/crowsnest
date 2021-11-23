#!/usr/bin/env bash
# Crow's Nest
# A multiple Cam and Stream Service for mainsailOS
# Written by Stephan Wendel aka KwadFan
# Copyright 2021
# https://github.com/mainsail-crew/crowsnest
# GPL V3
# Version 2
########

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
    local pids=$(jobs -pr)
    echo -e "Killed by user ...\r\nGoodBye ...\r"
    [ -n "$pids" ] && kill $pids && sleep 5 && kill -9 $pids
}
##

function err_exit {
    if [ "${1}" != "0" ]; then
        echo -e "ERROR: Error ${1} occured on line ${2}"
        echo -e "ERROR: Stopping $(basename "$0")."
        echo -e "Goodbye..."
    fi
    if [ -n "$(jobs -pr)" ]; then
        kill $(jobs -pr)
    fi
    exit 1    
}

### Init ERR Trap
trap 'err_exit $? $LINENO' ERR

### Import config from custompios.
function import_config {
    if [ -f "${HOME}/crowsnest/custompios/crowsnest/config" ]; then
        source ${HOME}/crowsnest/custompios/crowsnest/config
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
        sudo rm -rf ${HOME}/mjpg-streamer > /dev/null
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
        sudo rm -f ${HOME}/klipper_logs/webcamd.log > /dev/null
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

### Install Dependencies
## Enable buster-backports ( needed for golang-go > 1.11 )
function enable_backports {
    local template sources
    template="${HOME}/crowsnest/file_templates/buster-backports.list"
    sources="/etc/apt/sources.list.d/"
    if [ "$(grep -c "buster" /etc/apt/sources.list)" -ne "0" ]; then
        echo -e "\n'Debian 10 Buster' ( or based of ) detected ..."
        echo -e "We need to install Debian Backports for golang >=1.11\n"
        echo -en "Adding buster-backports to 'apt' ...\r"
        sudo cp "${template}" "${sources}" &> /dev/null
        echo -e "Adding buster-backports to 'apt' ... [OK]\r"
        echo -e "Adding buster-backports keyring to 'apt' ...\r"
        sudo apt-key adv --keyserver keyring.debian.org --recv-keys 648ACFD622F3D138
        sudo apt-key adv --keyserver keyring.debian.org --recv-keys 0E98404D386FA1D9
        echo -e "Adding buster-backports keyring to 'apt' ... [OK]\r"
        echo -e "\nRunning 'apt update' to initialize backports ..."
        sudo apt update
    fi
}

function install_crowsnest {
    local template servicefile logrotatefile bin_path webcamd_bin
    bin_path="/usr/local/bin"
    webcamd_bin="${HOME}/crowsnest/webcamd"
    template="$PWD/sample_configs/${CROWSNEST_DEFAULT_CONF}"
    servicefile="$PWD/file_templates/webcamd.service"
    logrotatefile="${HOME}/crowsnest/file_templates/logrotate_webcamd"
    echo -e "\nInstall webcamd Service ..."
    ## Install Dependencies
    echo -e "Installing 'crowsnest' Dependencies ..."
    sudo apt install --yes --no-install-recommends $CROWSNEST_DEPS > /dev/null
    echo -e "Installing 'crowsnest' Dependencies ... [OK]"
    ## Link webcamd to $PATH
    echo -en "Linking webcamd ...\r"
    sudo ln -sf "${webcamd_bin}" "${bin_path}" > /dev/null
    echo -e "Linking webcamd ... [OK]\r"
    ## Copy webcam.conf
    # Make sure not to overwrite existing!
    if [ ! -f "${CROWSNEST_DEFAULT_CONF_DIR}/webcam.conf" ]; then
        echo -en "Copying webcam.conf ...\r"
        sudo -u "${BASE_USER}" cp -rf $PWD/sample_configs/${CROWSNEST_DEFAULT_CONF} "${CROWSNEST_DEFAULT_CONF_DIR}"/webcam.conf
        echo -e "Copying webcam.conf ... [OK]\r"
    fi
    ## Link webcamd.service
    echo -en "Copying webcamd.service file ...\r"
    sudo ln -sf "${servicefile}" /etc/systemd/system/webcamd.service > /dev/null
    echo -e "Copying webcamd.service file ... [OK]\r"
    ## Link logrotate
    echo -en "Linking logrotate file ...\r"
    sudo ln -sf "${logrotatefile}" /etc/logrotate.d/webcamd
    echo -e "Linking logrotate file ... [OK]\r"
    echo -en "Reload systemd to enable new deamon ...\r"
    sudo systemctl daemon-reload
    echo -e "Reload systemd to enable new daemon ... [OK]"
    echo -en "Enable webcamd.service on boot ...\r"
    sudo systemctl enable webcamd.service
    echo -e "Enable webcamd.service on boot ... [OK]\r"
}

function install_ustreamer {
    local bin_path ustreamer_bin ustreamer_dump_bin
    ustreamer_bin="${HOME}/ustreamer/ustreamer"
    ustreamer_dump_bin="${HOME}/ustreamer/ustreamer-dump"
    bin_path="/usr/local/bin"
    echo -e "\nInstalling ustreamer ..."
    echo -e "Installing ustreamer Dependencies ..."
    sudo apt install --yes --no-install-recommends $CROWSNEST_USTREAMER_DEPS > /dev/null
    echo -e "Installing ustreamer Dependencies ... \t[OK]"
    echo -e "Cloning ustreamer Repo ..."
    pushd ${HOME} > /dev/null
    git clone "${CROWSNEST_USTREAMER_REPO_SHIP}" --depth=1
    popd > /dev/null
    echo -e "Cloning ustreamer Repo ... [OK]"
    pushd ${HOME}/ustreamer > /dev/null
    echo -e "Compiling ustreamer ..."
    if [ "${CROWSNEST_USTREAMER_WITH_OMX}" = "y" ] && \
        [ "${CROWSNEST_USTREAMER_WITH_GPIO}" = "y" ]; then
        echo -e "Compile ustreamer with OMX and GPIO Support..."
        WITH_OMX=1 WITH_GPIO=1 make -j$(nproc)
    elif [ "${CROWSNEST_USTREAMER_WITH_OMX}" = "y" ] && \
        [ "${CROWSNEST_USTREAMER_WITH_GPIO}" = "n" ]; then
        echo -e "Compile ustreamer with OMX Support..."
        WITH_OMX=1 make -j $(nproc)
    else
        echo -e"Compile ustreamer without OMX and GPIO Support..."
        make -j $(nproc)
    fi
    popd > /dev/null
    echo -en "Linking ustreamer ...\r"
    sudo ln -sf "${ustreamer_bin}" "${bin_path}" > /dev/null
    sudo ln -sf "${ustreamer_dump_bin}" "${bin_path}" > /dev/null
    echo -e "Linking ustreamer ... [OK]\r"
    echo -e "Installing ustreamer ... [OK]"
}

function install_v4l2rtspserver {
    local bin_path v4l2rtsp_bin
    v4l2rtsp_bin="${HOME}/v4l2rtspserver/v4l2rtspserver"
    bin_path="/usr/local/bin"
    echo -e "\nInstalling v4l2rtspserver ..."
    echo -e "Installing v4l2rtspserver Dependencies ..."
    sudo apt install --yes --no-install-recommends $CROWSNEST_V4L2RTSP_DEPS > /dev/null
    echo -e "Installing v4l2rtspserver Dependencies ... \t[OK]"
    echo -e "Cloning v4l2rtspserver Repo ..."
    pushd ${HOME} > /dev/null
    git clone "${CROWSNEST_V4L2RTSP_REPO_SHIP}" --depth=1
    popd > /dev/null
    echo -e "Cloning v4l2rtspserver Repo ... [OK]"
    pushd ${HOME}/v4l2rtspserver > /dev/null
    echo -e "Compiling v4l2rtspserver ..."
    cmake . && make -j $(nproc)
    popd > /dev/null
    echo -en "Linking v4l2rtspserver ...\r"
    sudo ln -sf "${v4l2rtsp_bin}" "${bin_path}" > /dev/null
    echo -e "Linking v4l2rtspserver ... [OK]\r"
    echo -e "Installing v4l2rtspserver ... [OK]"
}

## Stay for later use.
# function install_rtspsimple {
#     local bin_path rtsp_bin
#     bin_path="/usr/local/bin"
#     rtsp_bin="${CROWSNEST_RTSPSIMPLE_DIR}/rtsp-simple-server"
#     # We are using armv6l Version to be downwards compatible.
#     ## Install Dependencies
#     echo -e "Installing 'rtsp-simple-server' Dependencies ..."
#     sudo apt install --yes --no-install-recommends $CROWSNEST_RTSPSIMPLE_DEPS > /dev/null
#     echo -e "Installing 'rtsp-simple-server' Dependencies ... [OK]"
#     # Download Release Binary
#     echo -e "Download 'rtsp-simple-server' ..."
#     curl -o /tmp/rtsp-simple-server.tar.gz -L "${CROWSNEST_RTSPSIMPLE_RELEASE}"
#     echo -e "Download 'rtsp-simple-server' ... [OK]"
#     echo -en "Unpacking 'rtsp-simple-server' ...\r"
#     mkdir -p "${CROWSNEST_RTSPSIMPLE_DIR}" > /dev/null
#     tar xfz /tmp/rtsp-simple-server.tar.gz -C "${CROWSNEST_RTSPSIMPLE_DIR}" > /dev/null
#     echo -e "Unpacking 'rtsp-simple-server' ... [OK]"
#     echo -en "Linking 'rtsp-simple-server' ...\r"
#     sudo ln -sf "${rtsp_bin}" "${bin_path}" > /dev/null
#     echo -e "Linking 'rtsp-simple-server' ... [OK]\r"
# }

function install_raspicam_fix {
    sudo sh -c 'echo "bcm2835-v4l2" >> /etc/modules'
}

#### MAIN
install_cleanup_trap
import_config
welcome_msg
detect_existing_webcamd
## Golang not needed for now!
# enable_backports
echo -e "Running apt update first ..."
sudo apt update 
install_crowsnest
install_ustreamer
install_v4l2rtspserver
# install_rtspsimple
install_raspicam_fix
goodbye_msg

exit 0