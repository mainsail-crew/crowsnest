#!/usr/bin/env bash
#### webcamd - A webcam Service for multiple Cams and Stream Services.
####
#### Written by Stephan Wendel aka KwadFan <me@stephanwe.de>
#### Copyright 2021
#### https://github.com/mainsail-crew/crowsnest
####
#### This File is distributed under GPLv3
####

# shellcheck enable=require-variable-braces

## Exit on Error
set -Ee

## Debug
# set -x

# Global Vars
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


### Uninstall crowsnest
function ask_uninstall {
    local remove
    if  [ -x "/usr/local/bin/webcamd" ] && [ -d "${HOME}/crowsnest" ]; then
        read -rp "Do you REALLY want to remove existing 'crowsnest'? (YES/NO) " remove
        if [ "${remove}" = "YES" ]; then
            sudo echo -e "\nPlease enter your password!"
            uninstall_crowsnest
            uninstall_v4l2rtsp
            # go unsinstaller is deprecated will be removed in future
            uninstall_go
            remove_raspicam_fix
            remove_logrotate
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

#obsolete will be removed in future
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

#obsolete will be removed in future
function uninstall_go {
    if [ -n "$(whereis -b go | awk '{print $2}')" ]; then
        echo -e "\nFound $(go version)\n"
    else
        echo -e "No Version of Go Lang found ... [SKIPPED]"
    fi
    if  [ -d "/usr/local/go" ] && [ -f "${HOME}/.gorc" ]; then
        sudo rm -rf "$(whereis -b go | awk '{print $2}')"
        rm -f "${HOME}/.gorc"
        sudo rm -rf "${HOME}/golang"
        sed -i '/# Add Go/d;/.gorc/d' "${HOME}/.profile"
        echo -e "\nUninstall complete!"
    fi
}

function remove_raspicam_fix {
    if [ -f /proc/device-tree/model ] &&
    grep -q "Raspberry" /proc/device-tree/model ; then
        echo -en "Removing Raspicam Fix ...\r"
        sudo sed -i '/bcm2835/d' /etc/modules
        sudo rm -f /etc/modprobe.d/bcm2835-v4l2.conf
        echo -e "Removing Raspicam Fix ... [OK]"
    else
        echo -e "This is not a Raspberry Pi!"
        echo -e "Removing Raspicam Fix ... [SKIPPED]"
    fi
}

function remove_logrotate {
    echo -en "Removing Logrotate Rule ...\r"
    sudo rm -f /etc/logrotate.d/webcamd
    echo -e "Removing Logrotate Rule ... [OK]"
}

#### MAIN
install_cleanup_trap
welcome_msg
ask_uninstall

exit 0
