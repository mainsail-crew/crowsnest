#!/usr/bin/env bash
#### crowsnest - A webcam Service for multiple Cams and Stream Services.
####
#### Written by Stephan Wendel aka KwadFan <me@stephanwe.de>
#### Copyright 2021 - 2022
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
TITLE="\e[31mcrowsnest\e[0m - A webcam daemon for multiple Cams and stream services."
CN_CONFIG_ENVPATH="$(find "${HOME}" -name "crowsnest.env")"

# Message Vars
CN_OK="\e[32mOK\e[0m"
CN_SK="\e[33mSKIPPED\e[0m"

### Check non-root
if [[ ${UID} = '0' ]]; then
    echo -e "\n\tYOU DONT NEED TO RUN UNINSTALLER AS ROOT!"
    echo -e "\tYou will be prompted for 'sudo' passwd"
    exit 1
fi

### Functions

### Messages
### Welcome Message
welcome_msg() {
    echo -e "${TITLE}\n"
    echo -e "\t\e[34mAhoi!\e[0m"
    echo -e "\tTo sad that you want to uninstall crowsnest :("
    echo -e "\tThis will take a while ... "
    echo -e "\tPlease reboot after installation has finished.\n"
    sleep 1
}

goodbye_msg() {
    echo -e "Please remove manually the 'crowsnest' folder in ${HOME}\n"
    echo -e "\tRemove [update manager crowsnest] section from moonraker.conf,before reboot!\n"
    echo -e "After that is done, please reboot!\nGoodBye...\n"
}

### General
## These two functions are reused from custompios common.sh
## Credits to guysoft!
## https://github.com/guysoft/CustomPiOS

install_cleanup_trap() {
    # kills all child processes of the current process on SIGINT or SIGTERM
    trap 'cleanup' SIGINT SIGTERM
}

cleanup() {
    # make sure that all child processed die when we die
    echo -e "Killed by user ...\r\nGoodBye ...\r"
    # shellcheck disable=2046
    [ -n "$(jobs -pr)" ] && kill $(jobs -pr) && sleep 5 && kill -9 $(jobs -pr)
}
##

err_exit() {
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
ask_uninstall() {
    local remove
    if  [ -x "/usr/local/bin/crowsnest" ] && [ -d "${HOME}/crowsnest" ]; then
        while true; do
        read -erp "Do you REALLY want to remove existing 'crowsnest'? (y/N) " -i "N" remove
            case "${remove}" in
                y|Y|yes|Yes|YES)
                    source_env_file
                    uninstall_crowsnest
                    remove_raspicam_fix
                    remove_logrotate
                    ask_remove_config
                    goodbye_msg
                    break
                ;;
                n|N|no|No|NO)
                    echo -e "\nYou answered '${remove}'! Uninstall will be aborted..."
                    echo -e "GoodBye...\n"
                    exit 1
                ;;
                *)
                    echo -e "\nInvalid input, please try again."
                ;;
            esac
        done
    else
        echo -e "\n'crowsnest' seems not installed."
        echo -e "Exiting. GoodBye ..."
    fi
}

source_env_file() {
    # shellcheck disable=SC1090
    . "${CN_CONFIG_ENVPATH}"
}

uninstall_crowsnest() {
    local servicefile bin_path
    servicefile="/etc/systemd/system/crowsnest.service"
    bin_path="/usr/local/bin/crowsnest"
    # Dirty hack to grant sudo priviledges
    # and not overwriting next \r line
    sudo sh -c 'echo "" > /dev/null'
    echo -en "\nStopping crowsnest.service ...\r"
    sudo systemctl stop crowsnest.service &> /dev/null
    echo -e "Stopping crowsnest.service ... \t[${CN_OK}]\r"
    echo -en "\nDisable crowsnest.service ...\r"
    sudo systemctl disable crowsnest.service &> /dev/null
    echo -e "Disable crowsnest.service ... \t[${CN_OK}]\r"
    echo -en "Uninstalling crowsnest.service...\r"
    if [[ -f "${servicefile}" ]]; then
        sudo rm -f "${servicefile}"
    fi
    if [[ -x "${bin_path}" ]]; then
        sudo rm -f "${bin_path}"
    fi
    echo -e "Uninstalling crowsnest.service...[${CN_OK}]\r"
    if [[ -n "${CN_CONFIG_ENVPATH}" ]]; then
        echo -en "Removing crowsnest.env ...\r"
        sudo rm -f "${CN_CONFIG_ENVPATH}"
        echo -e "Removing crowsnest.env ... [${CN_OK}]\r"
    fi
}

ask_remove_config() {
    local config reply
    config="${CROWSNEST_ARGS/-c /}"
    while true; do
        read -erp "Do you want to remove crowsnest.conf? [y/N]: " -i "N" reply
        case "${reply}" in
            [yY]* )
                sudo rm -f "${config}"
                echo -e "Removing 'crowsnest.conf' ... [${CN_OK}]\r"
                break
            ;;
            [nN]* )
                echo -e "Removing 'crowsnest.conf' ... [${CN_SK}]\r"
                break
            ;;
            * )
                echo -e "\e[31mERROR: Not a valid choice, try again ...\e[0m"
            ;;
        esac
    done
    return 0
}

remove_raspicam_fix() {
    if [[ -f /etc/modprobe.d/bcm2835-v4l2.conf ]] &&
    [[ -f /proc/device-tree/model ]] &&
    grep -q "Raspberry" /proc/device-tree/model ; then
        echo -en "Removing Raspicam Fix ...\r"
        sudo sed -i '/bcm2835/d' /etc/modules
        sudo rm -f /etc/modprobe.d/bcm2835-v4l2.conf
        echo -e "Removing Raspicam Fix ... [${CN_OK}]"
    else
        echo -e "Removing Raspicam Fix ... [${CN_SK}]"
        echo -e "\tThis is not a Raspberry Pi"
        echo -e "\tor Raspicamfix not installed ... \n"
    fi
}

function remove_logrotate {
    echo -en "Removing Logrotate Rule ...\r"
    sudo rm -f /etc/logrotate.d/crowsnest
    echo -e "Removing Logrotate Rule ... [${CN_OK}]"
}

#### MAIN
install_cleanup_trap
welcome_msg
ask_uninstall

exit 0
