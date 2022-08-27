#!/usr/bin/env bash
# Crow's Nest
# A multiple Cam and Stream Service for mainsailOS
# Written by Stephan Wendel aka KwadFan <me@stephanwe.de>
# Copyright 2021 - 2022
# https://github.com/mainsail-crew/crowsnest
# GPL V3
########

# shellcheck enable=require-variable-braces

## disabled SC2086 for some lines because there we want 'word splitting'

# Exit on errors
set -Ee

# Global Vars
BASE_USER=$(whoami)
TITLE="crowsnest - A Webcam Daemon for Raspberry Pi OS"

### Non root
if [ ${UID} == '0' ]; then
    echo -e "DO NOT RUN THIS SCRIPT AS ROOT!\nExiting..."
    exit 1
fi

### noninteractive Check
if [ "${DEBIAN_FRONTEND}" != "noninteractive" ]; then
    export DEBIAN_FRONTEND=noninteractive
fi

### Functions

### Messages
### Welcome Message
function welcome_msg {
    echo -e "${TITLE}\n"
    echo -e "\tSome Parts of the Installer requires 'root' privileges."
    echo -e "\tYou will be prompted for your 'sudo' password, if needed.\n"
}

function detect_msg {
    echo -e "Found an existing 'crowsnest'. This will be removed."
    echo -e "Since we dont use mjpg-streamer it will also removed."
    echo -e "You can use KIAUH for example to reinstall.\n"
}

function goodbye_msg {
    echo -e "\nInstallation complete.\n\tPlease reboot your machine!"
    echo -e "I hope you enjoy crowsnest, GoodBye ..."
}

### Installer

### General
## These two functions are reused from custompios common.sh
## Credits to guysoft!
## https://github.com/guysoft/CustomPiOS

function install_cleanup_trap() {
    # kills all child processes of the current process on SIGINT or SIGTERM
    trap 'cleanup' SIGINT SIGTERM
}

function cleanup() {
    # make sure that all child processed die when we die
    echo -e "Killed by user ...\r\nGoodBye ...\r"
    # shellcheck disable=2046
    [ -n "$(jobs -pr)" ] && kill $(jobs -pr) && sleep 5 && kill -9 $(jobs -pr)
}
##

function err_exit {
    if [ "${1}" != "0" ]; then
        echo -e "ERROR: Error ${1} occured on line ${2}"
        echo -e "ERROR: Stopping $(basename "$0")."
        echo -e "Goodbye..."
    fi
    # shellcheck disable=2046
    [ -n "$(jobs -pr)" ] && kill $(jobs -pr) && sleep 5 && kill -9 $(jobs -pr)
    exit 1
}

### Init ERR Trap
trap 'err_exit $? $LINENO' ERR

## helper func
## call get_os_version <keyword>
function get_os_version {
    if [ -n "${1}" ]; then
        grep -c "${1}" /etc/os-release
    fi
}

### Import config from custompios.
function import_config {
    ## Source Custom config if present
    if [ -s tools/config.local ]; then
        # shellcheck disable=SC1091
        source tools/config.local
        return 0
    fi

    ## X86 machines
    if [ "$(uname -m)" == "x86_64" ] &&
    [ -f tools/config.x86 ]; then
        # shellcheck disable=SC1091
        source tools/config.x86
        return 0
    fi

    ## rpi os buster
    if [ "$(uname -m)" != "x86_64" ] &&
    [ "$(get_os_version buster)" != "0" ] &&
    [ -f "tools/config.buster" ]; then
        # shellcheck disable=SC1091
        source tools/config.buster
        return 0
    fi

    ## bullseye
    if [ "$(uname -m)" != "x86_64" ] &&
    [ "$(get_os_version bullseye)" != "0" ] &&
    [ -f "tools/config.bullseye" ]; then
        # shellcheck disable=SC1091
        source tools/config.bullseye
        return 0
    fi

    ## Ubuntu ARM (armv7l) tested on v20.04
    if [ "$(uname -m)" == "armv7l" ] &&
    [ "$(get_os_version ubuntu)" != "0" ] &&
    [ -f "tools/config.buntu64" ]; then
        # shellcheck disable=SC1091
        source tools/config.buntu64
        return 0
    fi

    ## Ubuntu ARM (aarch64) tested on v22.04
    if [ "$(uname -m)" == "aarch64" ] &&
    [ "$(get_os_version ubuntu)" != "0" ] &&
    [ -f "tools/config.buntu64" ]; then
        # shellcheck disable=SC1091
        source tools/config.buntu64
        return 0
    fi

    ## armbian buster
    if [ "$(uname -m)" != "x86_64" ] &&
    [ -f "/etc/armbian-release" ] &&
    [ "$(get_os_version buster)" != "0" ] &&
    [ -f "tools/config.armbian-buster" ]; then
        # shellcheck disable=SC1091
        source tools/config.armbian-buster
        return 0
    fi

    ## armbian bullseye
    if [ "$(uname -m)" != "x86_64" ] &&
    [ -f "/etc/armbian-release" ] &&
    [ "$(get_os_version bullseye)" != "0" ] &&
    [ -f "tools/config.armbian-bullseye" ]; then
        # shellcheck disable=SC1091
        source tools/config.armbian-bullseye
        return 0
    fi

    ## armbian jammy
    if [ "$(uname -m)" != "x86_64" ] &&
    [ -f "/etc/armbian-release" ] &&
    [ "$(get_os_version ubuntu)" != "0" ] &&
    [ -f "tools/config.buntu64" ]; then
        # shellcheck disable=SC1091
        source tools/config.buntu64
        return 0
    fi
}

### Detect legacy webcamd.
function detect_existing_webcamd {
    local remove
    if  [ -x "/usr/local/bin/webcamd" ] && [ -d "${HOME}/mjpg-streamer" ]; then
        detect_msg
        read -erp "Do you want to remove existing 'webcamd'? (y/N) " -i "N" remove
        case "${remove}" in
            y|Y|yes|Yes|YES)
                echo -en "\nStopping webcamd.service ...\r"
                sudo systemctl stop webcamd.service &> /dev/null
                echo -e "Stopping webcamd.service ... \t[OK]\r"
                remove_existing_webcamd
            ;;

            n|N|no|No|NO)
                echo -e "\nYou have to remove webcamd to use crowsnest!"
                echo -e "Installation will be aborted..."
                echo -e "GoodBye...\n"
                exit 1
            ;;
            *)
                echo -e "\nYou answered '${remove}'! Invalid input ... [EXITING]"
                echo -e "GoodBye...\n"
                exit 1
            ;;
        esac
    fi
}

### Remove existing webcamd
function remove_existing_webcamd {
    if [ -x "/usr/local/bin/webcamd" ]; then
        echo -en "Removing 'webcamd' ...\r"
        sudo rm -f /usr/local/bin/webcamd > /dev/null
        echo -e "Removing 'webcamd' ... \t\t[OK]\r"
    fi
    if [ -d "${HOME}/mjpg-streamer" ]; then
        echo -en "Removing 'mjpg-streamer' ...\r"
        sudo rm -rf "${HOME}"/mjpg-streamer > /dev/null
        echo -e "Removing 'mjpg-streamer' ... \t[OK]\r"
    fi
    if [ -f "/etc/systemd/system/webcamd.service" ]; then
        echo -en "Removing 'webcamd.service' ...\r"
        sudo systemctl disable webcamd.service &> /dev/null
        sudo rm -f /etc/systemd/system/webcamd.service > /dev/null
        echo -e "Removing 'webcamd.service' ... \t[OK]\r"
    fi
    if [ -f "/var/log/webcamd.log" ]; then
        echo -en "Removing 'webcamd.log' ...\r"
        sudo rm -f /var/log/webcamd.log > /dev/null
        sudo rm -f "${HOME}"/klipper_logs/webcamd.log > /dev/null
        echo -e "Removing 'webcamd.log' ... \t[OK]\r"
    fi
    if [ -f "/etc/logrotate.d/webcamd" ]; then
        echo -en "Removing 'webcamd' logrotate...\r"
        sudo rm -f /etc/logrotate.d/webcamd > /dev/null
        echo -e "Removing 'webcamd' logrotate ... \t[OK]\r"
    fi
    echo -e "\nOld 'webcamd' completly removed."
    echo -e "webcam.txt kept,but no longer necessary ..."
}


function install_crowsnest {
    local addconf bin_path logrotatefile moonraker_conf moonraker_update
    local crowsnest_bin servicefile template
    bin_path="/usr/local/bin"
    crowsnest_bin="${HOME}/crowsnest/crowsnest"
    template="${PWD}/sample_configs/${CROWSNEST_DEFAULT_CONF}"
    servicefile="${PWD}/file_templates/crowsnest.service"
    logrotatefile="${HOME}/crowsnest/file_templates/logrotate_crowsnest"
    moonraker_conf="${HOME}/klipper_config/moonraker.conf"
    moonraker_update="${PWD}/file_templates/moonraker_update.txt"
    ## helper func moonraker update_manager
    function add_update_entry {
        if [ -f "${moonraker_conf}" ]; then
            # make sure no file exist
            if [ -f "/tmp/moonraker.conf" ]; then
                sudo rm -f /tmp/moonraker.conf
            fi
            echo -e "Adding [update_manager] entry ..."
            sudo -u "${BASE_USER}" \
            cp "${moonraker_conf}" "${moonraker_conf}.backup" &&
            cat "${moonraker_conf}" "${moonraker_update}" > /tmp/moonraker.conf &&
            cp -rf /tmp/moonraker.conf "${moonraker_conf}"
            if [ "${UNATTENDED}" == "true" ]; then
                sudo rm -f "${moonraker_conf}.backup"
            fi
        else
            echo -e "moonraker.conf is missing ... [SKIPPED]"
        fi
    }
    echo -e "\nInstall crowsnest Service ..."
    ## Install Dependencies
    echo -e "Installing 'crowsnest' Dependencies ..."
    # shellcheck disable=2086
    sudo apt install --yes --no-install-recommends ${CROWSNEST_CROWSNEST_DEPS} > /dev/null
    echo -e "Installing 'crowsnest' Dependencies ... [OK]"
    ## Link crowsnest to $PATH
    echo -en "Linking crowsnest ...\r"
    sudo ln -sf "${crowsnest_bin}" "${bin_path}" > /dev/null
    echo -e "Linking crowsnest ... [OK]\r"
    ## Copy crowsnest.conf
    # Make sure config directory exists!
    if [ ! -d "${CROWSNEST_DEFAULT_CONF_DIR}" ]; then
        sudo -u "${BASE_USER}" mkdir -p "${CROWSNEST_DEFAULT_CONF_DIR}"
    fi
    # Make sure not to overwrite existing!
    if [ ! -f "${CROWSNEST_DEFAULT_CONF_DIR}/crowsnest.conf" ]; then
        echo -en "Copying crowsnest.conf ...\r"
        sudo -u "${BASE_USER}" cp -rf "${template}" "${CROWSNEST_DEFAULT_CONF_DIR}"/crowsnest.conf
        echo -e "Copying crowsnest.conf ... [OK]\r"
    fi
    ## Copy crowsnest.service
    echo -en "Copying crowsnest.service file ...\r"
    sudo cp -rf "${servicefile}" /etc/systemd/system/crowsnest.service > /dev/null
    if [ ! "${BASE_USER}" == "pi" ]; then
        sudo sed -i 's|pi|'"${BASE_USER}"'|g' /etc/systemd/system/crowsnest.service
    fi
    echo -e "Copying crowsnest.service file ... [OK]\r"
    ## Copy logrotate
    echo -en "Linking logrotate file ...\r"
    sudo cp -rf "${logrotatefile}" /etc/logrotate.d/crowsnest
    if [ ! "${BASE_USER}" == "pi" ]; then
        sudo sed -i 's|pi|'"${BASE_USER}"'|g' /etc/logrotate.d/crowsnest
    fi
    echo -e "Linking logrotate file ... [OK]\r"
    ## update systemd if not unattended
    if [ "${UNATTENDED}" == "false" ] && [ "$(stat -c %i /)" == "2" ]; then
        echo -en "Reload systemd to enable new deamon ...\r"
        sudo systemctl daemon-reload
        echo -e "Reload systemd to enable new daemon ... [OK]"
    fi
    ## enable crowsnest.service
    echo -en "Enable crowsnest.service on boot ...\r"
    sudo systemctl enable crowsnest.service &> /dev/null
    echo -e "Enable crowsnest.service on boot ... [OK]\r"
    ## Add moonraker update manager entry
    ## Unattended
    if [ "${UNATTENDED}" == "true" ] &&
    [ "${CROWSNEST_ADD_CROWSNEST_MOONRAKER}" == "1" ] &&
    [ -f "${moonraker_conf}" ]; then
        echo -en "Adding Crowsnest Update Manager entry to moonraker.conf ...\r"
        add_update_entry
        echo -e "Adding Crowsnest Update Manager entry to moonraker.conf ... [OK]"
    fi
    ## Manual install
    if [ "${UNATTENDED}" != "true" ] &&
    [ "${CROWSNEST_ADD_CROWSNEST_MOONRAKER}" != "0" ]; then
        while true; do
            read -erp "Do you want to add [update_manager] entry? (y/N) " -i "N" addconf
            case "${addconf}" in
                y|Y|yes|Yes|YES)
                    if [ "$(grep -c "crowsnest" "${moonraker_conf}")" == "0" ]; then
                        add_update_entry
                    else
                        echo -e "Update Manager entry already exists moonraker.conf ... [SKIPPED]"
                    fi
                    break
                ;;

                n|N|no|No|NO)
                    echo -e "Adding Crowsnest Update Manager entry to moonraker.conf ... [SKIPPED]"
                    break
                ;;

                *)
                echo -e "\nInvalid input, please try again."
                ;;
            esac
        done
    fi

    ## add $USER to group video
    echo -en "Add User ${BASE_USER} to group 'video' ...\r"
    if [ "$(groups | grep -c video)" == "0" ]; then
        sudo usermod -aG video "${BASE_USER}" > /dev/null
        echo -e "Add User ${BASE_USER} to group 'video' ... [OK]"
    else
        echo -e "Add User ${BASE_USER} to group 'video' ... [SKIPPED]"
        echo -e "==> User ${BASE_USER} is already in group 'video'"
    fi
}

function clone_ustreamer {
    ## remove bin/ustreamer if exist
    if [ -d bin/ustreamer ]; then
        rm -rf bin/ustreamer
    fi
    git clone "${CROWSNEST_USTREAMER_REPO_SHIP}" \
    -b "${CROWSNEST_USTREAMER_REPO_BRANCH}" bin/ustreamer
    ## Buster workaround
    ## ustreamer support omx only till version 4.13
    ## so stick to that version
    if [ "$(get_os_version buster)" != "0" ]; then
        pushd bin/ustreamer &> /dev/null || exit 1
        git reset --hard 61ab2a8
        popd &> /dev/null || exit 1
    fi
}

function build_apps {
    echo -e "Build dependend Stream Apps ..."
    echo -e "Cloning ustreamer repository ..."
    clone_ustreamer
    echo -e "Installing 'ustreamer' Dependencies ..."
    # shellcheck disable=2086
    sudo apt install --yes --no-install-recommends ${CROWSNEST_USTREAMER_DEPS} > /dev/null
    echo -e "Installing 'ustreamer' Dependencies ... [OK]"
    pushd bin > /dev/null
    make all
    popd > /dev/null
}

function install_raspicam_fix {
    if [ -f /proc/device-tree/model ] &&
    grep -q "Raspberry" /proc/device-tree/model ; then
        echo -en "Applying Raspicam Fix ... \r"
        sudo sh -c 'echo "bcm2835-v4l2" >> /etc/modules'
        sudo cp file_templates/bcm2835-v4l2.conf /etc/modprobe.d/
        echo -e "Applying Raspicam Fix ... [OK]"
    else
        echo -e "This is not a Raspberry Pi!"
        echo -e "Applying Raspicam Fix ... [SKIPPED]"
    fi
}

function enable_legacy_cam {
    local cfg
    cfg="/boot/config.txt"
    echo -en "Enable legacy camera stack ... \r"
    sudo sed -i "s/camera_auto_detect=1/#camera_auto_detect=1/" "${cfg}"
    if [ "$(grep -c "start_x" "${cfg}")" == "0" ]; then
        sudo crudini --set --inplace "${cfg}" all start_x 1 &> /dev/null
    fi
    if [ "$(grep -c "gpu_mem" "${cfg}")" == "0" ]; then
        sudo crudini --set --inplace "${cfg}" pi4 gpu_mem 256 &> /dev/null
        sudo crudini --set --inplace "${cfg}" all gpu_mem 128 &> /dev/null
    fi
    echo -e "Enable legacy camera stack ... [OK]"
}

#### MAIN
while getopts "z" arg; do
    case ${arg} in
        z)
            echo "WARN: Running in UNATTENDED Mode ..."
            set -x
            UNATTENDED="true"
            ;;
        *)
            UNATTENDED="false"
        ;;
    esac
done
install_cleanup_trap
import_config
welcome_msg
if [ "${UNATTENDED}" != "true" ]; then
    detect_existing_webcamd
fi
echo -e "Running apt update first ..."
sudo apt update
install_crowsnest
build_apps
if [ "${UNATTENDED}" != "true" ] &&
[ "${CROWSNEST_FORCE_RASPICAMFIX}" != "0" ]; then
    install_raspicam_fix
fi
if [ "$(get_os_version bullseye)" != "0" ] &&
[ -f "/boot/config.txt" ]; then
    enable_legacy_cam
fi
goodbye_msg

exit 0
