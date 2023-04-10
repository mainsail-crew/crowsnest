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

is_raspbian() {
    if [[ -f /boot/config.txt ]] && [[ -f /etc/rpi-issue ]]; then
        echo "1"
    else
        echo "0"
    fi
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

install_env_file() {
    local env_file env_target
    env_file="${PWD}/resources/crowsnest.env"
    env_target="${CROWSNEST_ENV_PATH}/crowsnest.env"
    sudo -u "${BASE_USER}" cp -f "${env_file}" "${env_target}"
    sed -i "s|%CONFPATH%|${CROWSNEST_CONFIG_PATH}|" "${env_target}"
    [[ -f "${env_target}" ]] &&
    grep -q "${BASE_USER}" "${env_target}" || return 1
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
