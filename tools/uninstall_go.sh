#!/usr/bin/env bash
#### webcamd - A webcam Service for multiple Cams and Stream Services.
####
#### Written by Stephan Wendel aka KwadFan <me@stephanwe.de>
#### Copyright 2021
#### https://github.com/mainsail-crew/crowsnest
####
#### This File is distributed under GPLv3
####

# shellcheck enable=require-variable-braces

# Error Handling
set -e

### Non root
if [ ${UID} == '0' ]; then
    echo -e "DO NOT RUN THIS SCRIPT AS ROOT!\nExiting..."
    exit 1
fi

if [ -n "$(whereis -b go | awk '{print $2}')" ]; then
    echo -e "\nFound $(go version)\n"
else
    echo -e "No Version of Go Lang found ... Aborting!"
    exit 1
fi

if  [ -d "/usr/local/go" ] && [ -f "${HOME}/.gorc" ]; then
    read -rp "Do you want to remove existing 'Go' installation? (YES/NO) " remove
    if [ "${remove}" = "YES" ]; then
        sudo rm -rf "$(whereis -b go | awk '{print $2}')"
        rm -f "${HOME}/.gorc"
        sudo rm -rf "${HOME}/golang"
        sed -i '/# Add Go/d;/.gorc/d' "${HOME}/.profile"
        echo -e "\nUninstall complete!"
        exit 0
    else
        echo -e "\nYou answered '${remove}'! Uninstall will be aborted..."
        echo -e "GoodBye...\n"
        exit 1
    fi
fi
