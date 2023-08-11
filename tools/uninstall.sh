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

# Global Vars
TITLE="\e[31mcrowsnest\e[0m - A webcam daemon for multiple cams and stream services."
SRC_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd -P)"
SERVICE_FILE="/etc/systemd/system/crowsnest.service"


# Global func
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

## Messages
welcome_msg() {
    msg "${TITLE}\n"
    msg "\t\e[34mAhoi!\e[0m"
    msg "\tTo sad that you want to uninstall crowsnest :("
    msg "\tThis will take a while ... "
    msg "\tPlease reboot after uninstallation has finished.\n"
    sleep 1
}

goodbye_msg() {
    msg "Please remove manually the 'crowsnest' folder in ${HOME}\n"
    msg "\tRemove [update manager crowsnest] section from moonraker.conf,before reboot!\n"
    msg "After that is done, please reboot!\nGoodBye...\n"
}

error_msg() {
    msg "Something went wrong!\nPlease copy the last output and head over to\n"
    msg "\thttps://discord.gg/mainsail\n"
    msg "open a ticket in #supportforum ..."
}

## Interactive
ask_uninstall() {
    local remove
        while true; do
        read -erp "Do you REALLY want to remove existing 'crowsnest'? (y/N) " -i "N" remove
            case "${remove}" in
                [yY]*)
                    break
                ;;
                [nN]*)
                    msg "\nYou answered '${remove}'! Uninstall will be aborted..."
                    msg "GoodBye...\n"
                    exit 1
                ;;
                *)
                    msg "\nInvalid input, please try again."
                ;;
            esac
        done
}

ask_remove_config() {
    local reply
    while true; do
        read -erp "Do you want to remove crowsnest.conf? [y/N]: " -i "N" reply
        case "${reply}" in
            [yY]* )
                remove_conf_file
                break
            ;;
            [nN]* )
                status_msg "Removing 'crowsnest.conf' ..." "2"
                break
            ;;
            * )
                msg "\e[31mERROR: Not a valid choice, try again ...\e[0m"
            ;;
        esac
    done
    return 0
}

## remove funcs
remove_service_file() {
    if [[ ! -f "${SERVICE_FILE}" ]]; then
        status_msg "Removing service file ..." "2"
        msg "\t==> File does not exist!"
        return 0
    fi
    if [[ -f "${SERVICE_FILE}" ]]; then
        if sudo rm -f "${SERVICE_FILE}"; then
            status_msg "Removing service file ..." "0"
        else
            status_msg "Removing service file ..." "1"
        fi
    fi
}

remove_env_file() {
    local env_file
    env_file="${CROWSNEST_ENV_PATH}/crowsnest.env"
    if [[ ! -f "${env_file}" ]]; then
        status_msg "Removing environment file ..." "2"
        msg "\t==> File does not exist!"
        return 0
    fi
    if [[ -f "${env_file}" ]]; then
        if sudo rm -f "${env_file}"; then
            status_msg "Removing environment file ..." "0"
        else
            status_msg "Removing environment file ..." "1"
        fi
    fi
}

remove_conf_file() {
    local conf_file
    conf_file="${CROWSNEST_CONFIG_PATH}/crowsnest.conf"
    if [[ ! -f "${conf_file}" ]]; then
        status_msg "Removing 'crowsnest.conf' ..." "2"
        msg "\t==> File does not exist!"
        return 0
    fi
    if [[ -f "${conf_file}" ]]; then
        if sudo rm -f "${conf_file}"; then
            status_msg "Removing 'crowsnest.conf' ..." "0"
        else
            status_msg "Removing 'crowsnest.conf' ..." "1"
        fi
    fi
}

remove_log_files() {
    local log_file
    log_file="${CROWSNEST_LOG_PATH}/crowsnest.log"
    if [[ ! -f "${log_file}" ]]; then
        status_msg "Removing 'crowsnest.log' ..." "2"
        msg "\t==> File does not exist!"
        return 0
    fi
    if [[ -f "${log_file}" ]]; then
        if sudo rm -f "${log_file}"; then
            status_msg "Removing 'crowsnest.log' ..." "0"
        else
            status_msg "Removing 'crowsnest.log' ..." "1"
        fi
    fi
}

remove_logrotate() {
    local logrotate_conf
    logrotate_conf="/etc/logrotate.d/crowsnest"
    if [[ ! -f "${logrotate_conf}" ]]; then
        status_msg "Removing Logrotate Rule ..." "2"
        msg "\t==> File does not exist!"
        return 0
    fi
    if [[ -f "${logrotate_conf}" ]]; then
        sudo rm -f /etc/logrotate.d/crowsnest || return 1
    fi
}

get_path() {
    local cn_base_path
    cn_base_path="$(
            dirname "$(grep "EnvironmentFile" < "${SERVICE_FILE}" | cut -f2 -d= )"
        )"
        cn_base_path="${cn_base_path%/*}"
        echo "${cn_base_path}"
}

main() {
    if [[ "${UID}" = '0' ]]; then
    msg "\n\tYOU DONT NEED TO RUN UNINSTALLER AS ROOT!"
    msg "\tYou will be prompted for 'sudo' password"
    exit 1
    fi

    welcome_msg

    [[ -f "${SERVICE_FILE}" ]] || (
        msg "\nERROR: File ${SERVICE_FILE} not found!"
        msg "\t ==> Crowsnest seems not to be installed ... [EXITING]"
        exit 1
    )

    ask_uninstall

    ## fake sudo
    sudo echo "fakesudo" >> /dev/null

    #shellcheck disable=SC1091
    [[ -f "${SRC_DIR}/.config" ]] && . "${SRC_DIR}/.config"
    DATA_DIR="$(get_path)"
    [[ -n "${CROWSNEST_CONFIG_PATH}" ]] || CROWSNEST_CONFIG_PATH="${DATA_DIR}/config"
    [[ -n "${CROWSNEST_LOG_PATH}" ]] || CROWSNEST_LOG_PATH="${DATA_DIR}/logs"
    [[ -n "${CROWSNEST_ENV_PATH}" ]] || CROWSNEST_ENV_PATH="${DATA_DIR}/systemd"

    if systemctl is-active crowsnest.service &> /dev/null; then
        if sudo systemctl stop crowsnest.service &> /dev/null; then
            status_msg "Stopping crowsnest service ..." "0"
        else
            status_msg "Stopping crowsnest service ..." "1"
        fi
    else
        status_msg "Stopping crowsnest service ..." "2"
        msg "\t==> crowsnest service is not running"
    fi

    if systemctl is-enabled crowsnest.service &> /dev/null; then
        if sudo systemctl disable crowsnest.service &> /dev/null; then
            status_msg "Disable crowsnest service ..." "0"
        else
            status_msg "Disable crowsnest service ..." "1"
        fi
    else
        status_msg "Disable crowsnest service ..." "2"
        msg "\t==> crowsnest service is enabled"
    fi


    remove_service_file

    remove_env_file

    if remove_logrotate; then
        status_msg "Removing Logrotate Rule ..." "0"
    else
        status_msg "Removing Logrotate Rule ..." "1"
    fi

    remove_log_files

    ask_remove_config

    goodbye_msg
}

main "${@}"
exit 0
