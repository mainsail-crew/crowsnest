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

# Exit on errors
set -Ee

# Debug
# set -x

## Funcs
get_host_arch() {
    uname -m
}

install_dependencies() {
    local pkgs=("${PKGLIST[@]}")
    if [[ "$(use_pi_specifics)" = "1" ]]; then
        pkgs+=("${PKGLIST_PI[@]}")
    fi
    apt-get --yes --no-install-recommends install "${pkgs[@]}" || return 1
}

create_filestructure() {
    for dir in "${CROWSNEST_CONFIG_PATH}" "${CROWSNEST_LOG_PATH%/*.*}" "${CROWSNEST_ENV_PATH}"; do
        if [[ ! -d "${dir}" ]]; then
            if sudo -u "${BASE_USER}" mkdir -p "${dir}"; then
                status_msg "Created ${dir} ..." "0"
            else
                status_msg "Created ${dir} ..." "1"
            fi
        else
            msg "Directory ${dir} already exists ..." "0"
        fi
    done || return 1
}

install_service_file() {
    local service_file target_dir
    service_file="${PWD}/resources/crowsnest.service"
    target_dir="/etc/systemd/system"

    if [[ -f "${target_dir}/crowsnest.service" ]]; then
        rm -f "${target_dir}/crowsnest.service"
    fi
    cp -f "${service_file}" "${target_dir}"
    sed -i 's|%USER%|'"${BASE_USER}"'|g;s|%ENV%|'"${CROWSNEST_ENV_PATH}/crowsnest.env"'|g;s|%PYTHON_VENV%|'"${CROWSNEST_VENV_PATH}"'|g' \
    "${target_dir}/crowsnest.service"
    [[ -f "${target_dir}/crowsnest.service" ]] &&
    grep -q "${BASE_USER}" "${target_dir}/crowsnest.service" || return 1
}

install_env_file() {
    local env_file env_target
    env_file="${PWD}/resources/crowsnest.env"
    env_target="${CROWSNEST_ENV_PATH}/crowsnest.env"
    sudo -u "${BASE_USER}" cp -f "${env_file}" "${env_target}"
    sed -i "s|%CONFPATH%|${CROWSNEST_CONFIG_PATH}|" "${env_target}"
    sed -i "s|%LOGPATH%|${CROWSNEST_LOG_PATH}|" "${env_target}"
    [[ -f "${env_target}" ]] &&
    grep -q "${CROWSNEST_CONFIG_PATH}" "${env_target}" && grep -q "${CROWSNEST_LOG_PATH}" "${env_target}" || return 1
}

backup_crowsnest_conf() {
    local extension
    extension="$(date +%Y-%m-%d-%H%M)"
    if [[ -f "${CROWSNEST_CONFIG_PATH}/crowsnest.conf" ]]; then
        msg "Found existing crowsnest.conf in ${CROWSNEST_CONFIG_PATH} ..."
        msg "\t ==> Creating backup as crowsnest.conf.${extension} ..."
        sudo -u "${BASE_USER}" mv "${CROWSNEST_CONFIG_PATH}/crowsnest.conf" "${CROWSNEST_CONFIG_PATH}/crowsnest.conf.${extension}"
    fi
}

install_crowsnest_conf() {
    local conf_template
    conf_template="${PWD}/resources/crowsnest.conf"
    backup_crowsnest_conf
    sudo -u "${BASE_USER}" cp -rf "${conf_template}" "${CROWSNEST_CONFIG_PATH}"
    [[ -f "${CROWSNEST_CONFIG_PATH}/crowsnest.conf" ]] || return 1
}

enable_service() {
    sudo systemctl enable crowsnest.service &> /dev/null || return 1
}

add_group_video() {
    if [[ "$(groups "${BASE_USER}" | grep -c video)" == "0" ]]; then
        if usermod -aG video "${BASE_USER}" > /dev/null; then
            status_msg "Add User ${BASE_USER} to group 'video' ..." "0"
        fi
    else
        status_msg "Add User ${BASE_USER} to group 'video' ..." "2"
        msg "\t==> User ${BASE_USER} is already in group 'video'"
    fi
}

dietpi_cs_settings() {
    sudo /boot/dietpi/func/dietpi-set_hardware rpi-codec enable
    sudo /boot/dietpi/func/dietpi-set_hardware rpi-camera enable

    if ! grep -q "camera_auto_detect=1" /boot/config.txt; then
        msg "\nAdd camera_auto_detect=1 to /boot/config.txt ...\n"
        echo "camera_auto_detect=1" >> /boot/config.txt
    fi
}

### Detect legacy webcamd.
detect_existing_webcamd() {
    local disable
    msg "Checking for mjpg-streamer ...\n"
    if  [[ -x "/usr/local/bin/webcamd" ]] && [[ -d "/home/${BASE_USER}/mjpg-streamer" ]]; then
        msg "Found an existing mjpg-streamer installation!"
        msg "This should be stopped and disabled!"
        while true; do
            read -erp "Do you want to stop and disable existing 'webcamd'? (Y/n) " -i "Y" disable
            case "${disable}" in
                y|Y|yes|Yes|YES)
                    msg "Stopping webcamd.service ..."
                    sudo systemctl stop webcamd.service &> /dev/null
                    status_msg "Stopping webcamd.service ..." "0"

                    msg "\nDisabling webcamd.service ...\r"
                    sudo systemctl disable webcamd.service &> /dev/null
                    status_msg "Disabling webcamd.service ..." "0"
                    return
                ;;

                n|N|no|No|NO)
                    msg "\nYou should disable and stop webcamd to use crowsnest without problems!\n"
                    return
                ;;
                *)
                    msg "You answered '${disable}'! Invalid input ..."                ;;
            esac
        done
    fi
    status_msg "Checking for mjpg-streamer ..." "0"
}
