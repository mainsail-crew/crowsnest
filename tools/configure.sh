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

# Exit on errors
set -Ee

## Debug
# set -x


# Global Vars
CN_CONFIG_USER=$(whoami)
CN_CONFIG_CONFIGFILE="tools/.config"
CN_CONFIG_ROOTPATH="/home/${CN_CONFIG_USER}/printer_data"
CN_CONFIG_CONFIGPATH="${CN_CONFIG_ROOTPATH}/config"
CN_CONFIG_LOGPATH="${CN_CONFIG_ROOTPATH}/logs"
CN_CONFIG_ENVPATH="${CN_CONFIG_ROOTPATH}/systemd"
CN_MOONRAKER_CONFIG_PATH="${CN_CONFIG_CONFIGPATH}/moonraker.conf"
CN_USTREAMER_REPO="https://github.com/pikvm/ustreamer.git"
CN_USTREAMER_BRANCH="master"
CN_CAMERA_STREAMER_REPO="https://github.com/ayufan-research/camera-streamer.git"
CN_CAMERA_STREAMER_BRANCH="master"

### Messages
header_msg() {
    clear
    echo -e "\e[34m\n #### Crowsnest Install Configurator ####\e[0m\n"
}

welcome_msg() {
    header_msg
    echo -e "This will guide you through install configuration"
    echo -e "After successful configuration use\n"
    echo -e "\t\e[32msudo make install\e[0m\n"
    echo -e "to install crowsnest ..."
}

abort_msg() {
    header_msg
    echo -e "Configuration aborted by user ... \e[31mExiting!\e[0m"
}

check_config_file_msg() {
    header_msg
    echo -e "\n\t\e[33mWarning:\e[0m Found an existing .config!\n"
}


default_path_msg() {
    echo -e "Hit ENTER to use default."
}

root_path_msg() {
    header_msg
    echo -e "Please specify path to your 'printer_data' root path\n"
    echo -e "For example: /home/pi/voron_data or /home/kwad/ender_data"
    echo -e "\t\e[34mNOTE:\e[0m File names are hardcoded! Also skip trailing backslash!"
    echo -e "\tDefault: \e[32m${CN_CONFIG_ROOTPATH}\e[0m\n"
}

config_path_msg() {
    header_msg
    echo -e "Please specify path to config file (crowsnest.conf)\n"
    echo -e "\t\e[34mNOTE:\e[0m File names are hardcoded! Also skip trailing backslash!"
    echo -e "\tDefault: \e[32m${CN_CONFIG_CONFIGPATH}\e[0m\n"
}

log_path_msg() {
    header_msg
    echo -e "Please specify path to log file (crowsnest.log)\n"
    echo -e "\t\e[34mNOTE:\e[0m File names are hardcoded! Also skip trailing backslash!"
    echo -e "\tDefault: \e[32m${CN_CONFIG_LOGPATH}\e[0m\n"
}

env_path_msg() {
    header_msg
    echo -e "Please specify path to service environment file (crowsnest.env)\n"
    echo -e "\t\e[34mNOTE:\e[0m File names are hardcoded! Also skip trailing backslash!"
    echo -e "\tDefault: \e[32m${CN_CONFIG_ENVPATH}\e[0m\n"
}

add_moonraker_entry_msg() {
    header_msg
    echo -e "Should the update_manager entry added to your moonraker.conf?\n"
    echo -e "\t\e[34mNOTE:\e[0m\n\tThis will only work if your moonraker.conf"
    echo -e "\tshares the same path as your crowsnest.conf!!!\n"
    echo -e "If you want/have to do that manually,\nplease see 'resources/moonraker_update.txt'"
    echo -e "Copy the content in your moonraker.conf\n"
}

goodbye_msg() {
    header_msg
    echo -e "\t\e[32mSuccessful\e[0m configuration."
    echo -e "\tIn order to install crowsnest, please run:\n"
    echo -e "\t\t\e[32msudo make install\e[0m\n"
    echo -e "Goodbye ..."
}

### funcs
continue_config() {
    local reply
    while true; do
        read -erp "Continue? [Y/n]: " -i "Y" reply
        case "${reply}" in
            [Yy]* )
                break
            ;;
            [Nn]* )
                abort_msg
                exit 0
            ;;
            * )
                echo -e "\e[31mERROR: Please type Y or N !\e[0m"
            ;;
        esac
    done
}

check_config_file() {
    local reply
    if [[ -f "${CN_CONFIG_CONFIGFILE}" ]]; then
        check_config_file_msg
        while true; do
            read -erp "Overwrite? [y/N]: " -i "N" reply
            case "${reply}" in
                [Yy]* )
                    rm -f tools/.config
                    break
                ;;
                [Nn]* )
                    abort_msg
                    exit 0
                ;;
                * )
                    echo -e "\e[31mERROR:\e[0m Please type Y or N !"
                ;;
            esac
        done
        return 0
    fi
    return 0
}

create_config_header() {
    {
    echo -e "BASE_USER=\"${CN_CONFIG_USER}\"";
    echo -e "CROWSNEST_USTREAMER_REPO_SHIP=\"${CN_USTREAMER_REPO}\"";
    echo -e "CROWSNEST_USTREAMER_REPO_BRANCH=\"${CN_USTREAMER_BRANCH}\""
    echo -e "CROWSNEST_CAMERA_STREAMER_REPO_SHIP=\"${CN_CAMERA_STREAMER_REPO}\"";
    echo -e "CROWSNEST_CAMERA_STREAMER_REPO_BRANCH=\"${CN_CAMERA_STREAMER_BRANCH}\""
    } >> "${CN_CONFIG_CONFIGFILE}"
}

specify_root_path() {
    local reply
    root_path_msg
    default_path_msg
    read -erp "Please enter path: " -i "${CN_CONFIG_ROOTPATH}" reply
    if [[ -n "${reply}" ]]; then
        CN_CONFIG_ROOTPATH="${reply}"
        CN_CONFIG_CONFIGPATH="${CN_CONFIG_ROOTPATH}/config"
        CN_CONFIG_LOGPATH="${CN_CONFIG_ROOTPATH}/logs"
        CN_CONFIG_ENVPATH="${CN_CONFIG_ROOTPATH}/systemd"
        CN_MOONRAKER_CONFIG_PATH="${CN_CONFIG_CONFIGPATH}/moonraker.conf"
    fi
    return 0
}

specify_config_path() {
    local reply
    config_path_msg
    default_path_msg
    read -erp "Please enter path: " -i "${CN_CONFIG_CONFIGPATH}" reply
    if [[ -z "${reply}" ]]; then
        echo -e "CROWSNEST_CONFIG_PATH=\"${CN_CONFIG_CONFIGPATH}\"" >> \
        "${CN_CONFIG_CONFIGFILE}"
        return 0
    fi
    if [[ -n "${reply}" ]]; then
        echo -e "CROWSNEST_CONFIG_PATH=\"${reply}\"" >> "${CN_CONFIG_CONFIGFILE}"
        CN_MOONRAKER_CONFIG_PATH="${reply}/moonraker.conf"
        return 0
    fi
}

specify_log_path() {
    local reply
    log_path_msg
    default_path_msg
    read -erp "Please enter path: " -i "${CN_CONFIG_LOGPATH}" reply
    if [[ -z "${reply}" ]]; then
        echo -e "CROWSNEST_LOG_PATH=\"${CN_CONFIG_LOGPATH}\"" >> \
        "${CN_CONFIG_CONFIGFILE}"
        return 0
    fi
    if [[ -n "${reply}" ]]; then
        echo -e "CROWSNEST_LOG_PATH=\"${reply}\"" >> "${CN_CONFIG_CONFIGFILE}"
        return 0
    fi
}

specify_env_path() {
    local reply
    env_path_msg
    default_path_msg
    read -erp "Please enter path: " -i "${CN_CONFIG_ENVPATH}" reply
    if [[ -z "${reply}" ]]; then
        echo -e "CROWSNEST_ENV_PATH=\"${CN_CONFIG_ENVPATH}\"" >> \
        "${CN_CONFIG_CONFIGFILE}"
        return 0
    fi
    if [[ -n "${reply}" ]]; then
        echo -e "CROWSNEST_ENV_PATH=\"${reply}\"" >> "${CN_CONFIG_CONFIGFILE}"
        return 0
    fi
}

add_moonraker_entry() {
    local reply
    add_moonraker_entry_msg
    while true; do
        read -erp "Add update_manager entry? [Y/n]: " -i "Y" reply
        case "${reply}" in
            [yY]*)
                echo -e "CROWSNEST_ADD_CROWSNEST_MOONRAKER=\"1\"" >> "${CN_CONFIG_CONFIGFILE}"
                echo "CROWSNEST_MOONRAKER_CONF_PATH=\"${CN_MOONRAKER_CONFIG_PATH}\"" \
                >> "${CN_CONFIG_CONFIGFILE}"
                break
            ;;
            [nN]*)
                echo -e "CROWSNEST_ADD_CROWSNEST_MOONRAKER=\"0\"" >> "${CN_CONFIG_CONFIGFILE}"
                break
            ;;
            * )
                    echo -e "\e[31mERROR:\e[0m Please type Y or N !"
            ;;
        esac
    done
}

### Main func
main() {
    welcome_msg
    continue_config
    check_config_file
    create_config_header
    specify_root_path
    specify_config_path
    specify_log_path
    specify_env_path
    add_moonraker_entry
    goodbye_msg
}

### MAIN
main
exit 0
