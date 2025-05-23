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

is_raspios() {
    if [[ -f /etc/rpi-issue ]]; then
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

is_speederpad() {
    if grep -q "Ubuntu 20.04." /etc/os-release &&
    [[ "$(uname -rm)" = "4.9.191 aarch64" ]]; then
        echo "1"
    else
        echo "0"
    fi
}

use_cs() {
    if { [[ "$(is_raspios)" = "1" ]] ||
    [[ "$(is_dietpi)" = "1" ]]; } &&
    [[ "$(is_pi5)" = "0" ]]; then
        echo "1"
    else
        echo "0"
    fi
}
