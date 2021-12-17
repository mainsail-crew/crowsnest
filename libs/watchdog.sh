#!/bin/bash

#### Watchdog

#### webcamd - A webcam Service for multiple Cams and Stream Services.
####
#### written by Stephan Wendel aka KwadFan
#### Copyright 2021
#### https://github.com/mainsail-crew/crowsnest
####
#### This File is distributed under GPLv3
####

# shellcheck enable=requires-variable-braces

# Exit upon Errors
set -e

#### Watchdog Functions and Variables
## Do not reuse functions from other libs/scripts!
# We want watchdog operating independently!

function clean_watchdog {
    rm -f /tmp/lost-*
}

function webcamd_watchdog {
    # Helper Functions
    function available {
    find "${1}" &> /dev/null
    echo "${?}"
    }

    function lost_dev {
        local lostfile
        lostfile="$(echo "${1}" | awk -F '/' '{print $NF}')"
        touch /tmp/lost-"${lostfile}"
    }

    function is_lost {
        local lostdev
        lostdev="$(echo "${1}" | awk -F '/' '{print $NF}')"
        find /tmp/lost-"${lostdev}" &> /dev/null
        echo "${?}"
    }

    function returned_dev {
        local lostdev
        lostdev="$(echo "${1}"| awk -F '/' '{print $NF}')"
        rm -f /tmp/lost-"${lostdev}" &> /dev/null
    }

    function get_conf_devices {
        local gcd
    for i in $(crudini --existing=file --get "${WEBCAMD_CFG}" | \
    sed '/webcamd/d' | cut -d ' ' -f2); do
        gcd+=("${i}")
    done
    echo "${gcd[@]}"
    }

    ### MAIN

    for i in $(get_conf_devices); do
        cc="$(crudini --get "${WEBCAMD_CFG}" "cam ${i}" "device" \
        | awk '{print $1}')"
        if [ "$(available "${cc}")" -ne 0 ] && [ "$(is_lost "${cc}")" -ne 0 ]; then
            log_msg "WATCHDOG: Lost Device: '${cc}'"
            lost_dev "${cc}"
        elif [ "$(is_lost "${cc}")" -eq 0 ] && [ "$(available "${cc}")" -eq 0 ]; then
            log_msg "WATCHDOG: Device '${cc}' returned."
            returned_dev "${cc}"
        fi
    done
}
