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

### Disable SC2317 due Trap usage
# shellcheck disable=SC2317

# Exit on errors
set -Ee

# Debug
# set -x

# Global vars
# Base Path
BASE_CN_BIN_PATH="$(dirname "$(readlink -f "${0}")")"

. "${BASE_CN_BIN_PATH%%/bin}/resources/backend_versions.txt"

# Clone Flags
CLONE_FLAGS=(--single-branch)

# Ustreamer repo
USTREAMER_PATH="ustreamer"
if [[ -z "${CROWSNEST_USTREAMER_REPO_SHIP}" ]]; then
    CROWSNEST_USTREAMER_REPO_SHIP="https://github.com/pikvm/ustreamer.git"
fi
if [[ -z "${CROWSNEST_USTREAMER_REPO_BRANCH}" ]]; then
    CROWSNEST_USTREAMER_REPO_BRANCH="master"
fi

# Camera-streamer repo
CSTREAMER_PATH="camera-streamer"
if [[ -z "${CROWSNEST_CAMERA_STREAMER_REPO_SHIP}" ]]; then
    CROWSNEST_CAMERA_STREAMER_REPO_SHIP="https://github.com/ayufan/camera-streamer.git"
fi
if [[ -z "${CROWSNEST_CAMERA_STREAMER_REPO_BRANCH}" ]]; then
    CROWSNEST_CAMERA_STREAMER_REPO_BRANCH="master"
fi


# Paths of repos
ALL_PATHS=(
    "${BASE_CN_BIN_PATH}"/"${USTREAMER_PATH}"
    "${BASE_CN_BIN_PATH}"/"${CSTREAMER_PATH}"
)

### Messages
error_msg_build() {
    printf "Something went wrong!\nPlease copy the latest output, head over to\n"
    printf "\thttps://discord.gg/mainsail\n"
    printf "and open a ticket in #supportforum..."
}

status_msg_build() {
    local msg status
    msg="${1}"
    status="${2}"
    printf "%s\r" "${msg}"
    if [[ "${status}" == "0" ]]; then
        printf "%s [\e[32mOK\e[0m]\n" "${msg}"
    fi
    if [[ "${status}" == "1" ]]; then
        printf "%s [\e[31mFAILED\e[0m]\n" "${msg}"
        error_msg_build
        exit 1
    fi
    if [[ "${status}" == "2" ]]; then
        printf "%s [\e[33mSKIPPED\e[0m]\n" "${msg}"
    fi
    if [[ "${status}" == "3" ]]; then
        printf "%s [\e[33mFAILED\e[0m]\n" "${msg}"
    fi
}

# Helper messages
show_help() {
    printf "Usage %s [options]\n" "$(basename "${0}")"
    printf "\t-h or --help\t\tShows this help message\n"
    printf "\t-b or --build\t\tBuild Apps\n"
    printf "\t-c or --clean\t\tClean Apps\n"
    printf "\t-d or --delete\t\tDelete cloned Apps\n"
    printf "\t-r or --reclone\t\tClone Apps again\n\n"
}

## Helper funcs
### Check if device is Raspberry Pi
is_raspberry_pi() {
    if [[ -f /proc/device-tree/model ]] &&
    grep -q "Raspberry" /proc/device-tree/model; then
        echo "1"
    else
        echo "0"
    fi
}

is_bookworm() {
    if [[ -f /etc/os-release ]]; then
        grep -cq "bookworm" /etc/os-release &> /dev/null && echo "1" || echo "0"
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

test_load_module() {
    if modprobe -n "${1}" &> /dev/null; then
        echo 1
    else
        echo 0
    fi
}

shallow_cs_dependencies_check() {
    printf "\nChecking for camera-streamer dependencies ...\n"

    printf "Checking if device is a Raspberry Pi ...\n"
    if [[ "$(is_raspberry_pi)" = "0" ]]; then
        status_msg_build "Checking if device is a Raspberry Pi ..." "3"
        printf "This device is not a Raspberry Pi therefore camera-streeamer cannot be installed ..."
        return 1
    fi
    status_msg_build "Checking if device is a Raspberry Pi ..." "0"

    printf "Checking if device is not running Ubuntu ...\n"
    if [[ "$(is_ubuntu_arm)" = "1" ]]; then
        status_msg_build "Checking if device is not running Ubuntu ..." "3"
        printf "This device is running Ubuntu therefore camera-streeamer cannot be installed ..."
        return 1
    fi
    status_msg_build "Checking if device is not running Ubuntu ..." "0"

    printf "Checking for required kernel module ...\n"
    SHALLOW_CHECK_MODULESLIST="bcm2835_codec"
    if [[ "$(test_load_module "${SHALLOW_CHECK_MODULESLIST}")" = "0" ]]; then
        status_msg_build "Checking for required kernel module ..." "3"
        printf "Not all required kernel modules for camera-streamer can be loaded ..."
        return 1
    fi
    status_msg_build "Checking for required kernel module ..." "0"

    printf "Checking for required packages ...\n"
    # Update the number below if you update SHALLOW_CHECK_PKGLIST
    SHALLOW_CHECK_PKGLIST="^(libavformat-dev|libavutil-dev|libavcodec-dev|liblivemedia-dev|libcamera-dev|libcamera-apps-lite)$"
    if [[ $(apt-cache search --names-only "${SHALLOW_CHECK_PKGLIST}" | wc -l) -lt 6 ]]; then
        status_msg_build "Checking for required packages ..." "3"
        printf "Not all required packages for camera-streamer can be installed ..."
        return 1
    fi
    status_msg_build "Checking for required packages ..." "0"

    status_msg_build "Checking for camera-streamer dependencies ..." "0"
    return 0
}

### Get avail mem
get_avail_mem() {
    grep "MemTotal" /proc/meminfo | awk '{print $2}'
}

## MAIN funcs
### Delete repo folder
delete_apps() {
    for path in "${ALL_PATHS[@]}"; do
        if [[ ! -d "${path}" ]]; then
            printf "'%s' does not exist! Delete skipped ...\n" "${path}"
        fi
        if [[ -d "${path}" ]]; then
            printf "Deleting '%s' ... \n" "${path}"
            rm -rf "${path}"
        fi
    done
}

### Clone ustreamer
clone_ustreamer() {
    if [[ -d "${BASE_CN_BIN_PATH}"/"${USTREAMER_PATH}" ]]; then
        printf "%s already exist ... [SKIPPED]\n" "${USTREAMER_PATH}"
        return
    fi

    printf "\nCloning ustreamer ...\n"
    git clone "${CROWSNEST_USTREAMER_REPO_SHIP}" \
        -b "${CROWSNEST_USTREAMER_REPO_BRANCH}" \
        "${BASE_CN_BIN_PATH}"/"${USTREAMER_PATH}" \
        "${CLONE_FLAGS[@]}"

    printf "\nReset to specified ustreamer commit ...\n"
    git -C "${BASE_CN_BIN_PATH}"/"${USTREAMER_PATH}" \
    reset --hard "${CROWSNEST_USTREAMER_REPO_COMMIT}"
}

### Clone camera-streamer
clone_cstreamer() {
    ## Special handling because only supported on Raspberry Pi
    [[ -n "${CROWSNEST_UNATTENDED}" ]] || CROWSNEST_UNATTENDED="0"

    ## If CROWSNEST_UNATTENDED is 1, CN_INSTALL_CS should be already set
    if [[ "${CROWSNEST_UNATTENDED}" = "0" ]] && [[ -z "${CN_INSTALL_CS}" ]]; then
        if shallow_cs_dependencies_check; then
            CN_INSTALL_CS="1"
        else
            CN_INSTALL_CS="0"
        fi
    fi

    if [[ "${CN_INSTALL_CS}" = "0" ]]; then
        printf "WARN: Cloning camera-streamer skipped! Device is not supported!"
        return
    fi

    if [[ -d "${BASE_CN_BIN_PATH}"/"${CSTREAMER_PATH}" ]]; then
        printf "%s already exist ... [SKIPPED]\n" "${CSTREAMER_PATH}"
        return
    fi

    CROWSNEST_CAMERA_STREAMER_REPO_COMMIT="${CROWSNEST_CAMERA_STREAMER_REPO_COMMIT_MASTER}"
    if [[ "$(is_bookworm)" = "1" ]]; then
        printf "\nBookworm detected!\n"
        printf "Using main branch of camera-streamer for Bookworm ...\n"
        CROWSNEST_CAMERA_STREAMER_REPO_BRANCH="main"
        CROWSNEST_CAMERA_STREAMER_REPO_COMMIT="${CROWSNEST_CAMERA_STREAMER_REPO_COMMIT_MAIN}"
    fi

    printf "\nCloning camera-streamer ...\n"
    git clone "${CROWSNEST_CAMERA_STREAMER_REPO_SHIP}" \
        -b "${CROWSNEST_CAMERA_STREAMER_REPO_BRANCH}" \
        "${BASE_CN_BIN_PATH}"/"${CSTREAMER_PATH}" \
        "${CLONE_FLAGS[@]}" --recurse-submodules --shallow-submodules

    printf "\nReset to specified camera-streamer commit ...\n"
    git -C "${BASE_CN_BIN_PATH}"/"${CSTREAMER_PATH}" \
    reset --hard "${CROWSNEST_CAMERA_STREAMER_REPO_COMMIT}"
}

### Clone Apps
clone_apps() {
    local apps
    apps="ustreamer cstreamer"
    for app in ${apps}; do
        clone_"${app}"
    done
}

### Run 'make clean' in cloned folders
clean_apps() {
    for app in "${ALL_PATHS[@]}"; do
        printf "\nRunning 'make clean' in %s ... \n" "${app}"
        pushd "${app}" &> /dev/null || exit 1
        make clean
        popd &> /dev/null || exit 1
    done
    printf "\nRunning 'make clean' ... [DONE]\n"
}

build_apps() {
    ## Determine Ramsize and export MAKEFLAG
    if [[ "$(get_avail_mem)" -le 524288 ]]; then
        USE_PROCS=-j1
    elif [[ "$(get_avail_mem)" -le 1048576 ]]; then
        USE_PROCS=-j2
    else
        USE_PROCS=-j4
    fi

    for path in "${ALL_PATHS[@]}"; do
        if [[ ! -d "${path}" ]]; then
            printf "'%s' does not exist! Build skipped ... [WARN]\n" "${path}"
        fi
        if [[ -d "${path}" ]]; then
            printf "Build '%s' using ${USE_PROCS##-j} Cores ... \n" "${path##*/}"
            pushd "${path}" &> /dev/null || exit 1
            make "${USE_PROCS}"
            popd &> /dev/null || exit 1
            printf "Build '%s' ... [SUCCESS]\n" "${path##*/}"
        fi
    done
}

## MAIN FUNC
main() {
    ## Error exit if no args given, show help
    if [[ $# -eq "0" ]]; then
        printf "ERROR: No options given ...\n"
        show_help
        exit 1
    fi
    ## Error exit if too many args given
    if [[ $# -gt "1" ]]; then
        printf "ERROR: Too many options given ...\n"
        show_help
        exit 1
    fi
    ## Get opts
    while true; do
        case "${1}" in
            -b|--build)
                build_apps
                break
            ;;
            -c|--clean)
                clean_apps
                break
            ;;
            -d|--delete)
                delete_apps
                break
            ;;
            -h|--help)
                show_help
                break
            ;;
            -r|--reclone)
                delete_apps
                clone_apps
                break
            ;;
            *)
                printf "Unknown option: %s" "${1}"
                show_help
                break
            ;;
        esac
    done
}

#### MAIN
main "${@}"
exit 0

#### EOF
