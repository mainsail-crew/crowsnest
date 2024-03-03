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
get_os_version() {
    if [[ -n "${1}" ]]; then
        grep -c "${1}" /etc/os-release &> /dev/null && echo "1" || echo "0"
    fi
}

get_host_arch() {
    uname -m
}

is_buster() {
    if [[ -f /etc/os-release ]]; then
        grep -cq "buster" /etc/os-release &> /dev/null && echo "1" || echo "0"
    fi
}

is_bookworm() {
    if [[ -f /etc/os-release ]]; then
        grep -cq "bookworm" /etc/os-release &> /dev/null && echo "1" || echo "0"
    fi
}

is_raspbian() {
    if [[ -f /boot/config.txt ]] && [[ -f /etc/rpi-issue ]]; then
        echo "1"
    else
        echo "0"
    fi
}

is_dietpi() {
    if [[ -f /boot/config.txt ]] && [[ -d /boot/dietpi ]]; then
        echo "1"
    else
        echo "0"
    fi
}

is_raspberry_pi() {
    if [[ -f /proc/device-tree/model ]] &&
    grep -q "Raspberry" /proc/device-tree/model; then
        echo "1"
    else
        echo "0"
    fi
}

is_pi5() {
    if [[ -f /proc/device-tree/model ]] &&
    grep -q "Raspberry Pi 5" /proc/device-tree/model; then
        echo "1"
    else
        echo "0"
    fi
}

is_ubuntu_arm() {
    if [[ "$(is_raspberry_pi)" = "1" ]] &&
    grep -q "ubuntu" /etc/os-release; then
        echo "1"
    else
        echo "0"
    fi
}

is_speederpad() {
    if grep -q "Ubuntu 20.04." /etc/os-release &&
    [[ "$(uname -rm)" = "4.9.191 aarch64" ]]; then
        echo "1"
    else
        echo "0"
    fi
}

test_load_module() {
    if modprobe -n "${1}" &> /dev/null; then
        echo 1
    else
        echo 0
    fi
}

shallow_cs_dependencies_check() {
    msg "Checking for camera-streamer dependencies ...\n"

    msg "Checking if device is a Raspberry Pi ...\n"
    if [[ "$(is_raspberry_pi)" = "0" ]]; then
        status_msg "Checking if device is a Raspberry Pi ..." "3"
        msg "This device is not a Raspberry Pi therefore camera-streeamer cannot be installed ..."
        return 1
    fi
    status_msg "Checking if device is a Raspberry Pi ..." "0"

    msg "Checking if device is not a Raspberry Pi 5 ...\n"
    if [[ "$(is_pi5)" = "1" ]]; then
        status_msg "Checking if device is not a Raspberry Pi 5 ..." "3"
        msg "This device is a Raspberry Pi 5 therefore camera-streeamer cannot be installed ..."
        return 1
    fi
    status_msg "Checking if device is not a Raspberry Pi 5 ..." "0"

    msg "Checking if device is not running Ubuntu ...\n"
    if [[ "$(is_ubuntu_arm)" = "1" ]]; then
        status_msg "Checking if device is not running Ubuntu ..." "3"
        msg "This device is running Ubuntu therefore camera-streeamer cannot be installed ..."
        return 1
    fi
    status_msg "Checking if device is not running Ubuntu ..." "0"

    msg "Checking for required kernel module ...\n"
    SHALLOW_CHECK_MODULESLIST="bcm2835_codec"
    if [[ "$(test_load_module ${SHALLOW_CHECK_MODULESLIST})" = "0" ]]; then
        status_msg "Checking for required kernel module ..." "3"
        msg "Not all required kernel modules for camera-streamer can be loaded ..."
        return 1
    fi
    status_msg "Checking for required kernel module ..." "0"

    msg "Checking for required packages ...\n"
    # Update the number below if you update SHALLOW_CHECK_PKGLIST
    SHALLOW_CHECK_PKGLIST="^(libavformat-dev|libavutil-dev|libavcodec-dev|liblivemedia-dev|libcamera-dev|libcamera-apps-lite)$"
    if [[ $(apt-cache search --names-only "${SHALLOW_CHECK_PKGLIST}" | wc -l) -lt 6 ]]; then
        status_msg "Checking for required packages ..." "3"
        msg "Not all required packages for camera-streamer can be installed ..."
        return 1
    fi
    status_msg "Checking for required packages ..." "0"

    status_msg "Checking for camera-streamer dependencies ..." "0"
    return 0
}

link_pkglist_rpi() {
    sudo -u "${BASE_USER}" ln -sf "${SRC_DIR}/libs/pkglist-rpi.sh" "${SRC_DIR}/pkglist.sh" &> /dev/null || return 1
}

link_pkglist_generic() {
    sudo -u "${BASE_USER}" ln -sf "${SRC_DIR}/libs/pkglist-generic.sh" "${SRC_DIR}/pkglist.sh" &> /dev/null || return 1
}

run_apt_update() {
    apt-get -q --allow-releaseinfo-change update
}

source_pkglist_file() {
    # shellcheck disable=SC1091
    . "${SRC_DIR}/pkglist.sh"
}

install_dependencies() {
    local dep
    local -a pkg
    pkg=()
    for dep in ${PKGLIST}; do
        pkg+=("${dep}")
    done
    apt-get --yes --no-install-recommends install "${pkg[@]}" || return 1
}

create_filestructure() {
    for dir in "${CROWSNEST_CONFIG_PATH}" "${CROWSNEST_LOG_PATH%/*.*}" "${CROWSNEST_ENV_PATH}"; do
        if [[ ! -d "${dir}" ]]; then
            if sudo -u "${BASE_USER}" mkdir -p "${dir}"; then
                status_msg "Created ${dir} ..." "0"
            else
                status_msg "Created ${dir} ..." "1"
            fi
        fi
        if [[ -d "${dir}" ]]; then
            msg "Directory ${dir} already exists ..." "0"
        fi
    done || return 1
}

link_main_executable() {
    local crowsnest_main_bin_path crowsnest_src_bin_path
    crowsnest_main_bin_path="/usr/local/bin"
    crowsnest_src_bin_path="${PWD}/crowsnest"

    if [[ -f "${crowsnest_main_bin_path}/crowsnest" ]]; then
        rm -f "${crowsnest_main_bin_path}/crowsnest"
    fi
    if [[ -f "${crowsnest_src_bin_path}" ]]; then
        ln -sf "${crowsnest_src_bin_path}" "${crowsnest_main_bin_path}"
    else
        msg "File ${crowsnest_src_bin_path} does not exist!"
        return 1
    fi
}

install_service_file() {
    local service_file target_dir
    service_file="${PWD}/resources/crowsnest.service"
    target_dir="/etc/systemd/system"

    if [[ -f "${target_dir}/crowsnest.service" ]]; then
        rm -f "${target_dir}/crowsnest.service"
    fi
    cp -f "${service_file}" "${target_dir}"
    sed -i 's|%USER%|'"${BASE_USER}"'|g;s|%ENV%|'"${CROWSNEST_ENV_PATH}/crowsnest.env"'|g' \
    "${target_dir}/crowsnest.service"
    [[ -f "${target_dir}/crowsnest.service" ]] &&
    grep -q "${BASE_USER}" "${target_dir}/crowsnest.service" || return 1
}

add_sleep_to_crowsnest_env() {
    local service_file
    env_file="${CROWSNEST_ENV_PATH}/crowsnest.env"

    if [[ -f "${env_file}" ]]; then
        sed -i 's/\(CROWSNEST_ARGS="[^"]*\)"/\1 -s"/' "${env_file}"
    fi
}

install_env_file() {
    local env_file env_target
    env_file="${PWD}/resources/crowsnest.env"
    env_target="${CROWSNEST_ENV_PATH}/crowsnest.env"
    sudo -u "${BASE_USER}" cp -f "${env_file}" "${env_target}"
    sed -i "s|%CONFPATH%|${CROWSNEST_CONFIG_PATH}|" "${env_target}"
    [[ -f "${env_target}" ]] &&
    grep -q "${CROWSNEST_CONFIG_PATH}" "${env_target}" || return 1
}

install_logrotate_conf() {
    local logrotatefile logpath
    logrotatefile="${PWD}/resources/logrotate_crowsnest"
    logpath="${CROWSNEST_LOG_PATH}/crowsnest.log"
    cp -rf "${logrotatefile}" /etc/logrotate.d/crowsnest
    sed -i "s|%LOGPATH%|${logpath}|g" /etc/logrotate.d/crowsnest
    [[ -f "/etc/logrotate.d/crowsnest" ]] &&
    grep -q "${logpath}" "/etc/logrotate.d/crowsnest" || return 1
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
    logpath="${CROWSNEST_LOG_PATH}/crowsnest.log"
    backup_crowsnest_conf
    sudo -u "${BASE_USER}" cp -rf "${conf_template}" "${CROWSNEST_CONFIG_PATH}"
    sed -i "s|%LOGPATH%|${logpath}|g" "${CROWSNEST_CONFIG_PATH}/crowsnest.conf"
    [[ -f "${CROWSNEST_CONFIG_PATH}/crowsnest.conf" ]] &&
    grep -q "${logpath}" "${CROWSNEST_CONFIG_PATH}/crowsnest.conf" || return 1
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

    if [[ "$(is_buster)" = "0" ]]; then
        if ! grep -q "camera_auto_detect=1" /boot/config.txt; then
            msg "\nAdd camera_auto_detect=1 to /boot/config.txt ...\n"
            echo "camera_auto_detect=1" >> /boot/config.txt
        fi
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
