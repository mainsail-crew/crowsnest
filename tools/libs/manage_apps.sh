#!/usr/bin/env bash

#### crowsnest - A webcam Service for multiple Cams and Stream Services.
####
#### Written by Patrick Gehrsitz aka mryel00 <mryel00.github@gmail.com>
#### Copyright 2025 - till today
#### https://github.com/mainsail-crew/crowsnest
####
#### This File is distributed under GPLv3
####

# shellcheck enable=require-variable-braces

# Exit on errors
set -Ee

# Debug
# set -x

TOOLS_LIB_DIR="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"
# shellcheck disable=SC1091
. "${TOOLS_LIB_DIR}/helper_fn.sh"
# shellcheck disable=SC1091
. "${TOOLS_LIB_DIR}/messages.sh"

# Ustreamer repo
if [[ -z "${CROWSNEST_USTREAMER_REPO_SHIP}" ]]; then
    CROWSNEST_USTREAMER_REPO_SHIP="https://github.com/pikvm/ustreamer.git"
fi
if [[ -z "${CROWSNEST_USTREAMER_REPO_BRANCH}" ]]; then
    CROWSNEST_USTREAMER_REPO_BRANCH="master"
fi
USTREAMER_PATH="bin/ustreamer"

# These are install dependencies for manual building
PKGLIST_USTREAMER=("git" "build-essential" "libevent-dev" "libjpeg-dev" "libbsd-dev" "pkg-config")

# Paths of repos
ALL_PATHS=(
    "${USTREAMER_PATH}"
)

APPS=("mainsail-ustreamer")
if [[ "$(use_pi_specifics)" = "1" ]]; then
    APPS+=("mainsail-spyglass")
    if [[ "$(is_pi5)" = "0" ]]; then
        APPS+=("mainsail-camera-streamer-raspi")
    fi
else
    APPS+=("mainsail-camera-streamer-generic")
fi

: "${BASE_USER:=${SUDO_USER:-${USER}}}"
CROWSNEST_VENV_PATH="/home/${BASE_USER}/crowsnest-env"

clone_ustreamer() {
    ## remove bin/ustreamer if exist
    if [[ -d bin/ustreamer ]]; then
        rm -rf bin/ustreamer
    fi
    sudo -u "${BASE_USER}" \
    git clone "${CROWSNEST_USTREAMER_REPO_SHIP}" \
    -b "${CROWSNEST_USTREAMER_REPO_BRANCH}" \
    --depth=1 --single-branch "${USTREAMER_PATH}"
}

get_avail_mem() {
    grep "MemTotal" /proc/meminfo | awk '{print $2}'
}

build_ustreamer() {
    ## Determine Ramsize and export MAKEFLAG
    if [[ "$(get_avail_mem)" -le 524288 ]]; then
        USE_PROCS=-j1
    elif [[ "$(get_avail_mem)" -le 1048576 ]]; then
        USE_PROCS=-j2
    else
        USE_PROCS=-j4
    fi

    if [[ ! -d "${USTREAMER_PATH}" ]]; then
        msg "'${USTREAMER_PATH}' does not exist! Build skipped ... [WARN]\n"
    else
        msg "Build '${USTREAMER_PATH##*/}' using ${USE_PROCS##-j} Cores ... \n"
        pushd "${USTREAMER_PATH}" &> /dev/null || exit 1
        make "${USE_PROCS}"
        popd &> /dev/null || exit 1
        msg "Build '${USTREAMER_PATH##*/}' ... [SUCCESS]\n"
    fi
}

install_apt_sources() {
    local id version_id

    id=$(grep '^ID=' /etc/os-release | cut -d'=' -f2 | cut -d'"' -f2)
    version_id=$(grep '^VERSION_ID=' /etc/os-release | cut -d'=' -f2 | cut -d'"' -f2)
    variant="generic"

    if [[ "$(is_raspios)" = "1" || "$(is_dietpi)" = "1" ]]; then
        variant="rpi"
        id="debian"
    fi

    if [[ "${id}" = "debian" ]] && [[ "${version_id}" = "11" ]]; then
        curl -s --compressed "https://apt.mainsail.xyz/mainsail.gpg.key" | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/mainsail.gpg > /dev/null
        curl -s --compressed --fail -o /etc/apt/sources.list.d/mainsail.list "https://apt.mainsail.xyz/mainsail-${id}-${version_id}-${variant}.list"
        echo "1"
    else
        if curl -s --compressed --fail -o /etc/apt/sources.list.d/mainsail.sources "https://apt.mainsail.xyz/mainsail-${id}-${version_id}-${variant}.sources"; then
            curl -s --compressed "https://apt.mainsail.xyz/mainsail.gpg.key" | gpg --dearmor | sudo tee /usr/share/keyrings/mainsail.gpg > /dev/null
            echo "1"
        else
            echo "0"
        fi
    fi
}

install_apt_streamer() {
    msg "Running apt-get update again ..."
    if run_apt_update; then
        status_msg "Running apt-get update again ..." "0"
    else
        status_msg "Running apt-get update again ..." "1"
    fi

    for pkg in "${APPS[@]}"; do
        if apt-get --yes --no-install-recommends install "${pkg}"; then
            echo "${pkg} installed successfully."
        else
            echo "${pkg} not found or failed to install."
        fi
    done
}

install_venv() {
    msg "Setup python venv ..."
    if [[ -d "${CROWSNEST_VENV_PATH}" ]]; then
        msg "Python venv already exists."
        delete_venv
    fi
    sudo -u "${BASE_USER}" python3 -m venv --system-site-packages "${CROWSNEST_VENV_PATH}"
}

install_apps() {
    msg "Setup Mainsail apt repository ..."
    if [[ "$(install_apt_sources)" = "0" ]]; then
        msg "We do not support your Distro with the Mainsail apt repository."
        msg "Trying to install ustreamer manually."
        msg "Installing build dependencies ..."
        apt-get --yes --no-install-recommends install "${PKGLIST_USTREAMER[@]}" || return 1
        msg "Cloning ustreamer repository ..."
        clone_ustreamer
        msg "Building ustreamer ..."
        build_ustreamer
    else
        msg "Install streamer apps ..."
        install_apt_streamer
    fi
}

setup_runtime_env() {
    install_venv
    install_apps
}

delete_venv() {
    msg "Deleting python venv ..."
    if [[ -d "${CROWSNEST_VENV_PATH}" ]]; then
        msg "Deleting '${CROWSNEST_VENV_PATH}' ... [DONE]"
        rm -rf "${CROWSNEST_VENV_PATH}"
    else
        msg "'${CROWSNEST_VENV_PATH}' does not exist! Delete ... [SKIPPED]"
    fi
}

delete_apps() {
    for path in "${ALL_PATHS[@]}"; do
        if [[ ! -d "${path}" ]]; then
            printf "'%s' does not exist! Delete ... [SKIPPED]\n" "${path}"
        fi
        if [[ -d "${path}" ]]; then
            printf "Deleting '%s' ... [DONE]\n" "${path}"
            rm -rf "${path}"
        fi
    done

    for pkg in "${APPS[@]}"; do
        if apt-get --yes remove "${pkg}"; then
            echo "${pkg} removed successfully."
        else
            echo "${pkg} not found or failed to remove."
        fi
    done
}

delete_runtime_env() {
    delete_venv
    delete_apps
}

reinstall_runtime_env() {
    delete_runtime_env
    setup_runtime_env
}

main() {
    ## Error exit if no args given, show help
    if [[ $# -eq "0" ]]; then
        printf "ERROR: No options given ...\n"
        exit 1
    fi
    ## Error exit if too many args given
    if [[ $# -gt "1" ]]; then
        printf "ERROR: Too many options given ...\n"
        exit 1
    fi
    ## Get opts
    while true; do
        case "${1}" in
            -i|--install)
                setup_runtime_env
                break
            ;;
            -d|--delete)
                delete_runtime_env
                break
            ;;
            -r|--reinstall)
                reinstall_runtime_env
                break
            ;;
            *)
                printf "Unknown option: %s" "${1}"
                break
            ;;
        esac
    done
}

## Error exit if no args given, show help
if [[ $# -gt "0" ]]; then
    main "${@}"
    exit 0
fi
