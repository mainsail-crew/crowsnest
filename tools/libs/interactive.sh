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
ask_reboot() {
    local reply
    while true; do
        read -erp "Reboot NOW? [y/N]: " -i "N" reply
        case "${reply}" in
            [yY]*)
                msg "Going to reboot in 5 seconds!"
                sleep 5
                reboot
            ;;
            [nN]*)
                msg "\n\e[31mNot to reboot may cause issues!"
                msg "Reboot as soon as possible!\e[0m\n"
                msg "Goodbye ..."
                break
            ;;
            * )
                msg "\e[31mERROR:\e[0m Please choose Y or N !"
            ;;
        esac
    done
}

ask_update_entry() {
    local reply run_add_update_entry
    run_add_update_entry="0"
    msg "\n"
    while true; do
        read -erp "Do you want to add 'update manager' entry to your moonraker.conf? [Y/n]: " -i "Y" reply
        case "${reply}" in
            [yY]*)
                msg "Trying to add 'update manager' entry to moonraker.conf ..."
                run_add_update_entry="1"
                break
            ;;
            [nN]*)
                msg "Please add the following to your moonraker.conf,"
                msg "if you want to recieve updates due moonraker's update function.\n"
                cat "${PWD}"/resources/moonraker_update.txt
                msg "\n"
                break
            ;;
            * )
                msg "\e[31mERROR:\e[0m Please choose Y or N !"
            ;;
        esac
    done
    if [[ "${run_add_update_entry}" = "1" ]]; then
        add_update_entry
    else
        return 0
    fi
}
