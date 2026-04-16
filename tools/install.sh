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
[[ -n "${CROWSNEST_SKIP_REBOOT_PROMPT}" ]] || CROWSNEST_SKIP_REBOOT_PROMPT="0"

### Crowsnest Dependencies
# shellcheck disable=SC2034
PKGLIST=("curl" "crudini" "python3" "python3-venv")
# shellcheck disable=SC2034
PKGLIST_PI=("python3-libcamera")

main() {
    . "${SRC_DIR}/libs/helper_fn.sh"
    . "${SRC_DIR}/libs/config.sh"
    . "${SRC_DIR}/libs/manage_apps.sh"
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

    if [[ "$(is_os_release "buster")" = "1" ]]; then
        not_supported_msg
        exit 1
    fi

    welcome_msg

    msg "Running apt-get update first ..."
    if run_apt_update; then
        status_msg "Running apt-get update first ..." "0"
    else
        status_msg "Running apt-get update first ..." "4"
    fi

    if [[ "${CROWSNEST_UNATTENDED}" != "1" ]]; then
        detect_existing_webcamd
    fi

    msg "Installing dependencies ...\n"
    if install_dependencies; then
        status_msg "Install dependencies ..." "0"
    else
        status_msg "Install dependencies ..." "1"
    fi

    import_config

    msg "Creating file structure ..."
    if create_filestructure; then
        status_msg "Creating file structure ..." "0"
    else
        status_msg "Creating file structure ..." "1"
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

    if setup_runtime_env; then
        status_msg "Setup streamer apps ..." "0"
    else
        status_msg "Setup streamer apps ..." "1"
    fi

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
        goodbye_msg
        if [[ "${CROWSNEST_SKIP_REBOOT_PROMPT}" = "0" ]]; then
            ask_reboot
        fi
    elif [[ "${CROWSNEST_UNATTENDED}" = "1" ]]; then
        if [[ "${CROWSNEST_ADD_CROWSNEST_MOONRAKER}" = "1" ]]; then
            add_update_entry
        fi
        unattended_success_msg
    fi


    unset DEBIAN_FRONTEND
}

main "${@}"
exit 0
