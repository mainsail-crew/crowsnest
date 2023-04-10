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
# shellcheck disable=SC1090,SC2154,SC2317

set -eou pipefail

TEST_SERVICE_FILE="/etc/systemd/system/crowsnest.service"


is_raspbian() {
    if [[ -f /boot/config.txt ]] && [[ -f /etc/rpi-issue ]]; then
        echo "1"
    else
        echo "0"
    fi
}

get_vars() {
    INSTALLED_AS="$(grep "User" /etc/systemd/system/crowsnest.service | cut -f2 -d= | sed 's/^ //' | cut -f1 -d' ')"
    REPO_PATH="$(grep "WorkingDirectory" /etc/systemd/system/crowsnest.service | cut -f2 -d= | sed 's/^ //' | cut -f1 -d' ')"
    MAIN_EXE="$(grep "ExecStart" /etc/systemd/system/crowsnest.service | cut -f2 -d= | sed 's/^ //' | cut -f1 -d' ')"
    ENV_FILE="$(grep "EnvironmentFile" /etc/systemd/system/crowsnest.service | cut -f2 -d= | sed 's/^ //' | cut -f1 -d' ')"
}

print_vars() {
    printf "TEST: Path to repository -> %s \n" "${REPO_PATH}"
    printf "TEST: Main executable -> %s \n" "${MAIN_EXE}"
    printf "TEST: EnvironmentFile -> %s \n" "${ENV_FILE}"
}

main() {
    clear
    printf "\nTest crowsnest installation ...\n"

    printf "TEST: service file installed? ... "
    [[ -f "${TEST_SERVICE_FILE}" ]] 2> /dev/null && printf "[OK]\n" || printf "[FAILED]\n"

    printf "TEST: Print service file ...\n"
    ([[ -f "${TEST_SERVICE_FILE}" ]] && cat "${TEST_SERVICE_FILE}") \
    || (
    printf "TEST: Not found or empty ...\n"
    printf "TEST: All tests aborted! Crowsnest not installed or missing!\n"
    exit 1
    )

    printf "TEST: service enabled? ... "
    if systemctl is-enabled crowsnest.service &> /dev/null; then
        printf "[OK]\n"
    else
        printf "[FAILED]\n"
    fi

    printf "TEST: Grab paths from service file ...\n"
    get_vars
    print_vars

    printf "TEST: Installed as non root user? ... "
    [[ "${INSTALLED_AS}" != "root" ]] 2> /dev/null && printf "[OK]\n"; \
    printf "\t-> Installed as user '%s'\n" "${INSTALLED_AS}"|| printf "[FAILED]\n"

    printf "TEST: Main script (crowsnest) installed? ... "
    [[ -x "${MAIN_EXE}" ]] 2> /dev/null && printf "[OK]\n" || printf "[FAILED]\n"

    printf "TEST: crowsnest.env installed? ... "
    [[ -f "${ENV_FILE}" ]] 2> /dev/null && printf "[OK]\n" || printf "[FAILED]\n"

    printf "TEST: Print EnvironmentFile file ...\n"
    [[ -s "${ENV_FILE}" ]] && cat "${ENV_FILE}" || printf "TEST: Not found or empty ...\n"

    printf "TEST: logrotate installed? ... "
    [[ -f "/etc/logrotate.d/crowsnest" ]] 2> /dev/null && printf "[OK]\n" || printf "[FAILED]\n"

    printf "TEST: Print logrotate file ...\n"
    [[ -s "/etc/logrotate.d/crowsnest" ]] && cat "/etc/logrotate.d/crowsnest" || printf "TEST: Not found or empty ...\n"

    printf "TEST: ustreamer repo cloned? ..."
    [[ -d "${REPO_PATH}/bin/ustreamer" ]] && printf "[OK]\n" || printf "[NOT FOUND]\n"

    printf "TEST: ustreamer binary build? ..."
    [[ -x "${REPO_PATH}/bin/ustreamer/ustreamer" ]] && printf "[YES]\n" || printf "[NO]\n"

    printf "TEST: camera-streamer repo cloned? ..."
    if [[ "$(is_raspbian)" = "1" ]]; then
        [[ -d "${REPO_PATH}/bin/camera-streamer" ]] && printf "[OK]\n" || printf "[NOT FOUND]\n"
        printf "TEST: camera-streamer binary build? ..."
        [[ -x "${REPO_PATH}/bin/camera-streamer/camera-streamer" ]] && printf "[YES]\n" || printf "[NO]\n"
    else
        printf "[NON RPI -> SKIPPED]\n"
    fi
}

main "${@}"
exit 0
