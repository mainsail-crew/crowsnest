#!/usr/bin/env bash

#### crowsnest - A webcam Service for multiple Cams and Stream Services.
####
#### Written by Stephan Wendel aka KwadFan <me@stephanwe.de>
#### Copyright 2021 - 2023
#### Co-authored by Patrick Gehrsitz aka mryel00 <mryel00.github@gmail.com>
#### Copyright 2023 - till today
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

    welcome_msg

    msg "Running apt-get update first ...\n"
    if run_apt_update; then
        status_msg "Running apt-get update first ..." "0"
    else
        status_msg "Running apt-get update first ..." "1"
    fi

    if [[ "${CROWSNEST_UNATTENDED}" != "1" ]]; then
        msg "Doing some tests ...\n"
        detect_existing_webcamd
        if shallow_cs_dependencies_check; then
            CN_INSTALL_CS="1"
        else
            CN_INSTALL_CS="0"
        fi
        status_msg "Doing some tests ..." "0"
    else
        if [[ "$(is_raspbian)" = "1" ]]; then
            CN_INSTALL_CS="1"
        else
            CN_INSTALL_CS="0"
        fi
    fi

    if [[ "${CN_INSTALL_CS}" = "1" ]]; then
        msg "Installing with camera-streamer ...\n"
        link_pkglist_rpi
    else
        msg "Installing without camera-streamer ...\n"
        link_pkglist_generic
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

    if [[ "$(is_speederpad)" = "1" ]]; then
        msg "\nSpeederpad detected!"
        msg "Add startup delay to environment file ...\n"
        add_sleep_to_crowsnest_env
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

    if [[ "$(is_bookworm)" = "1" ]] && [[ "${CN_INSTALL_CS}" = "1" ]]; then
        msg "\nBookworm detected!"
        msg "Using main branch of camera-streamer for Bookworm ...\n"
        CROWSNEST_CAMERA_STREAMER_REPO_BRANCH="main"
    fi

    build_apps

    if [[ "${CROWSNEST_UNATTENDED}" = "0" ]]; then
        set_gpu_mem
    fi

    if [[ "$(is_dietpi)" = "1" ]]; then
        msg "\nDietPi detected!"
        msg "Adjust settings for camera-streamer ...\n"
        dietpi_cs_settings
        status_msg "Adjust settings for camera-streamer ..." "0"
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
