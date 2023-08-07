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
# shellcheck source-path=SCRIPTDIR

# Exit on errors
set -Ee

# Debug
# set -x


## Global Vars
SRC_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd -P)"
[[ -n "${CROWSNEST_UNATTENDED}" ]] || CROWSNEST_UNATTENDED="0"

main() {
    . "${SRC_DIR}/libs/build_apps.sh"
    . "${SRC_DIR}/libs/config.sh"
    . "${SRC_DIR}/libs/core.sh"
    . "${SRC_DIR}/libs/interactive.sh"
    . "${SRC_DIR}/libs/messages.sh"
    . "${SRC_DIR}/libs/set_gpumem.sh"
    . "${SRC_DIR}/libs/update_manager.sh"


    if [[ "${DEBIAN_FRONTEND}" != "noninteractive" ]]; then
        export DEBIAN_FRONTEND=noninteractive
    fi

    if [[ "${SUDO_USER}" = "root" ]]; then
        not_as_root_msg
        exit 1
    fi

    if [[ -z "${SUDO_USER}" ]] && [[ "${CROWSNEST_UNATTENDED}" != "1" ]]; then
        need_sudo_msg
        exit 1
    fi

    [[ -n "${BASE_USER}" ]] || BASE_USER="${SUDO_USER}"


    if [[ "$(is_buster)" = "1" ]]; then
        not_supported_msg
        exit 1
    fi

    if [[ "$(is_raspbian)" = "1" ]]; then
        link_pkglist_rpi
    fi

    if [[ "$(is_raspbian)" = "0" ]]; then
        link_pkglist_generic
    fi

    welcome_msg

    msg "Running apt-get update first ...\n"
    if run_apt_update; then
        status_msg "Running apt-get update first ..." "0"
    else
        status_msg "Running apt-get update first ..." "1"
    fi

    source_pkglist_file
    msg "Installing dependencies ...\n"
    if install_dependencies ;then
        status_msg "Install dependencies ..." "0"
    else
        status_msg "Install dependencies ..." "1"
    fi

    import_config

    msg "Creating file structure ..."
    if create_filestructure ;then
        status_msg "Creating file structure ..." "0"
    else
        status_msg "Creating file structure ..." "1"
    fi


    if link_main_executable; then
        status_msg "Link crowsnest to /usr/local/bin ..." "0"
    else
        status_msg "Link crowsnest to /usr/local/bin ..." "1"
    fi

    if install_service_file; then
        status_msg "Install service file ..." "0"
    else
        status_msg "Install service file ..." "1"
    fi

    if install_env_file; then
        status_msg "Install environment file ..." "0"
    else
        status_msg "Install environment file ..." "1"
    fi

    if install_logrotate_conf; then
        status_msg "Install logrotate configuration ..." "0"
    else
        status_msg "Install logrotate configuration ..." "1"
    fi

    if install_crowsnest_conf; then
        status_msg "Install crowsnest.conf ..." "0"
    else
        status_msg "Install crowsnest.conf ..." "1"
    fi

    if enable_service; then
        status_msg "Enable crowsnest.service ..." "0"
    else
        status_msg "Enable crowsnest.service ..." "1"
    fi

    add_group_video

    build_apps

    if [[ "${CROWSNEST_UNATTENDED}" = "0" ]]; then
        set_gpu_mem
    fi

    if [[ "${CROWSNEST_UNATTENDED}" = "0" ]]; then
        ask_update_entry
    fi

    if [[ "${CROWSNEST_UNATTENDED}" = "1" ]] &&
    [[ "${CROWSNEST_ADD_CROWSNEST_MOONRAKER}" = "1" ]]; then
        add_update_entry
    fi

    if [[ "${CROWSNEST_UNATTENDED}" = "0" ]]; then
        goodbye_msg
        ask_reboot
    fi

    if [[ "${CROWSNEST_UNATTENDED}" = "1" ]]; then
        unattended_success_msg
    fi


    unset DEBIAN_FRONTEND
}

main "${@}"
exit 0
