#!/usr/bin/env bash
# Crow's Nest
# A multiple Cam and Stream Service for mainsailOS
# Written by Stephan Wendel aka KwadFan
# Copyright 2021
# https://github.com/mainsail-crew/crowsnest
# GPL V3
# Version 1.1
########

set -e

## Debug
# set -x

# Global Vars
BASE_USER=$(whoami)
TITLE="crowsnest - A Webcam Daemon for Raspberry Pi OS"

### Functions

### Messages
### Welcome Message
function welcome_msg {
    echo -e "${TITLE}\n"
    echo -e "\tSome Parts of the Uninstaller requires 'root' privileges."
    echo -e "\tYou will be prompted for your 'sudo' password, if needed.\n"
}

function goodbye_msg {
    echo -e "Please remove manually the 'crowsnest' folder in ${HOME}"
    echo -e "Remove [update manager webcamd] section from moonraker.conf!"
    echo -e "After that is done, please reboot!\nGoodBye...\n"
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


### Uninstall crowsnest
function ask_uninstall {
    local remove
    if  [ -x "/usr/local/bin/webcamd" ] && [ -d "${HOME}/crowsnest" ]; then
        read -rp "Do you REALLY want to remove existing 'crowsnest'? (YES/NO) " remove
        if [ "${remove}" = "YES" ]; then
            sudo echo -e "\nPlease enter your password!"
            uninstall_crowsnest
            uninstall_ustreamer
            uninstall_v4l2rtsp
            uninstall_rtspsimple
            remove_raspicam_fix
            goodbye_msg
        else
            echo -e "\nYou answered '${remove}'! Uninstall will be aborted..."
            echo -e "GoodBye...\n"
            exit 1
        fi
    else
        echo -e "\n'crowsnest' seems not installed."
        echo -e "Exiting. GoodBye ..."
    fi
}

function uninstall_crowsnest {
    local servicefile bin_path
    servicefile="/etc/systemd/system/webcamd.service"
    bin_path="/usr/local/bin/webcamd"
    echo -en "\nStopping webcamd.service ...\r"
    sudo systemctl stop webcamd.service &> /dev/null
    echo -e "Stopping webcamd.service ... \t[OK]\r"
    echo -en "Uninstalling webcamd.service...\r"
    if [ -f "${servicefile}" ]; then
        sudo rm -f "${servicefile}"
    fi
    if [ -x "${bin_path}" ]; then
        sudo rm -f "${bin_path}"
    fi
    echo -e "Uninstalling webcamd.service...[OK]\r"
}

function uninstall_ustreamer {
    local bin_path bin_dump_path ustreamer_dir
    bin_path="/usr/local/bin/ustreamer"
    bin_dump_path="/usr/local/bin/ustreamer-dump"
    ustreamer_dir="${HOME}/ustreamer"
    if [ -d "${ustreamer_dir}" ]; then
        echo -en "Uninstalling ustreamer ...\r"
        if [ -x "${bin_path}" ] && [ -x "${bin_dump_path}" ]; then
            sudo rm -f "${bin_path}" "${bin_dump_path}"
        fi
        sudo rm -rf "${ustreamer_dir}"
        echo -e "Uninstalling ustreamer ... [OK]\r"
    fi
}

function uninstall_rtspsimple {
    local bin_path rtspsimple_dir
    bin_path="/usr/local/bin/rtsp-simple-server"
    rtspsimple_dir="${HOME}/rtsp-simple-server"
    if [ -d "${rtspsimple_dir}" ]; then
        echo -en "Uninstalling 'rtsp-simple-server' ...\r"
        if [ -x "${bin_path}" ]; then
            sudo rm -f "${bin_path}"
        fi
        sudo rm -rf "${rtspsimple_dir}"
        echo -e "Uninstalling 'rtsp-simple-server' ... [OK]\r"
    fi
}

function uninstall_v4l2rtsp {
    local bin_path v4l2rtsp_dir
    bin_path="/usr/local/bin/v4l2rtspserver"
    v4l2rtsp_dir="${HOME}/v4l2rtspserver"
    if [ -d "${v4l2rtsp_dir}" ]; then
        echo -en "Uninstalling 'v4l2rtspserver' ...\r"
        if [ -x "${bin_path}" ]; then
            sudo rm -f "${bin_path}"
        fi
        sudo rm -rf "${v4l2rtsp_dir}"
        echo -e "Uninstalling 'v4l2rtspserver' ... [OK]\r"
    fi
}

function remove_raspicam_fix {
    echo -en "Removing Raspicam Fix ...\r"
    sudo sed -i '/bcm2835/d' /etc/modules
    echo -e "Removing Raspicam Fix ... [OK]"
}

#### MAIN
install_cleanup_trap
welcome_msg
ask_uninstall

exit 0