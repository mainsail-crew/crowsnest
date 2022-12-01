#!/usr/bin/env bash

#### crowsnest - A webcam Service for multiple Cams and Stream Services.
####
#### Written by Stephan Wendel aka KwadFan <me@stephanwe.de>
#### Copyright 2021 - 2022
#### https://github.com/mainsail-crew/crowsnest
####
#### This File is distributed under GPLv3
####

# shellcheck enable=require-variable-braces

# Exit on errors
set -Ee

# Debug
# set -x

# Global Vars
TITLE="\e[31mcrowsnest\e[0m - A webcam daemon for multiple Cams and stream services."
[[ -n "${BASE_USER}" ]] || BASE_USER="$(logname 2> /dev/null || echo "${PWD}" | cut -d'/' -f3)"
[[ -n "${CROWSNEST_UNATTENDED}" ]] || CROWSNEST_UNATTENDED="0"
[[ -n "${CROWSNEST_DEFAULT_CONF}" ]] || CROWSNEST_DEFAULT_CONF="resources/crowsnest.conf"

# Message Vars
CN_OK="\e[32mOK\e[0m"
CN_SK="\e[33mSKIPPED\e[0m"

### Global setup
### noninteractive Check
if [[ "${DEBIAN_FRONTEND}" != "noninteractive" ]]; then
    export DEBIAN_FRONTEND=noninteractive
fi

### Check non-root
if [[ ${UID} != '0' ]]; then
    echo -e "\n\tYOU NEED TO RUN INSTALLER AS ROOT!"
    echo -e "\tPlease try '\e[32msudo make install\e[0m'\n\nExiting..."
    exit 1
fi

### Global functions

### Messages
### Welcome Message
welcome_msg() {
    echo -e "${TITLE}\n"
    echo -e "\t\e[34mAhoi!\e[0m"
    echo -e "\tThank you for installing crowsnest ;)"
    echo -e "\tThis will take a while ... "
    echo -e "\tPlease reboot after installation has finished.\n"
    sleep 1
}

### Config Message
config_msg() {
    echo -e "\nConfig file not found!\n\tUsing defaults ..."
    echo -e "\tThis uses paths located in 'printer_data' of your Home Folder."
    exit 1
}

### Detect Message
detect_msg() {
    echo -e "Found an existing 'crowsnest' or mjpg-streamer"
    echo -e "This has to be removed..."
    echo -e "You can use KIAUH for example to reinstall.\n"
}

### Goodbye Message
goodbye_msg() {
    echo -e "\nInstallation \e[32msuccessful\e[0m.\n"
    echo -e "\t\e[33mTo take changes effect, you need to reboot your machine!\e[0m\n"
}

## These two functions are reused from custompios common.sh
## Credits to guysoft!
## https://github.com/guysoft/CustomPiOS

install_cleanup_trap() {
    # kills all child processes of the current process on SIGINT or SIGTERM
    trap 'cleanup' SIGINT SIGTERM
}

cleanup() {
    # make sure that all child processed die when we die
    echo -e "Killed by user ...\r\nGoodBye ...\r"
    [[ -n "$(jobs -pr)" ]] && kill "$(jobs -pr)" && sleep 5 && kill -9 "$(jobs -pr)"
}

err_exit() {
    if [[ "${1}" != "0" ]]; then
        echo -e "ERROR: Error ${1} occured on line ${2}"
        echo -e "ERROR: Stopping $(basename "$0")."
        echo -e "Goodbye..."
    fi
    [[ -n "$(jobs -pr)" ]] && kill "$(jobs -pr)" && sleep 5 && kill -9 "$(jobs -pr)"
    exit 1
}

## call get_os_version <keyword>
get_os_version() {
    if [[ -n "${1}" ]]; then
        grep -c "${1}" /etc/os-release
    fi
}

### Import config
import_config() {
    ## Source config if present
    if [[ -s tools/.config ]]; then
        # shellcheck disable=SC1091
        source tools/.config
        return 0
    fi
    if [[ ! -f tools/.config ]] &&
    [[ "${CROWSNEST_UNATTENDED}" != "1" ]]; then
        CROWSNEST_CONFIG_PATH="/home/${BASE_USER}/printer_data/config"
        CROWSNEST_LOG_PATH="/home/${BASE_USER}/printer_data/logs"
        CROWSNEST_ENV_PATH="/home/${BASE_USER}/printer_data/systemd"
        CROWSNEST_USTREAMER_REPO_SHIP="https://github.com/pikvm/ustreamer.git"
        CROWSNEST_USTREAMER_REPO_BRANCH="master"

    fi
}

create_filestructure() {
    for i in "${CROWSNEST_CONFIG_PATH}" "${CROWSNEST_LOG_PATH%/*.*}" "${CROWSNEST_ENV_PATH}"; do
        if [[ ! -d "${i}" ]]; then
            sudo -u "${BASE_USER}" mkdir -p "${i}"
        fi
    done
}

### Detect legacy webcamd.
detect_existing_webcamd() {
    local remove
    if  [ -x "/usr/local/bin/webcamd" ] && [ -d "${HOME}/mjpg-streamer" ]; then
        detect_msg
        read -erp "Do you want to remove existing 'webcamd'? (y/N) " -i "N" remove
        case "${remove}" in
            y|Y|yes|Yes|YES)
                echo -en "\nStopping webcamd.service ...\r"
                sudo systemctl stop webcamd.service &> /dev/null
                echo -e "Stopping webcamd.service ... \t[${CN_OK}]\r"
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
remove_existing_webcamd() {
    if [[ -x "/usr/local/bin/webcamd" ]]; then
        echo -en "Removing 'webcamd' ...\r"
        sudo rm -f /usr/local/bin/webcamd > /dev/null
        echo -e "Removing 'webcamd' ... \t\t[${CN_OK}]\r"
    fi
    if [[ -d "${HOME}/mjpg-streamer" ]]; then
        echo -en "Removing 'mjpg-streamer' ...\r"
        sudo rm -rf "${HOME}"/mjpg-streamer > /dev/null
        echo -e "Removing 'mjpg-streamer' ... \t[${CN_OK}]\r"
    fi
    if [[ -f "/etc/systemd/system/webcamd.service" ]]; then
        echo -en "Removing 'webcamd.service' ...\r"
        sudo systemctl disable webcamd.service &> /dev/null
        sudo rm -f /etc/systemd/system/webcamd.service > /dev/null
        echo -e "Removing 'webcamd.service' ... \t[${CN_OK}]\r"
    fi
    if [[ -f "/var/log/webcamd.log" ]]; then
        echo -en "Removing 'webcamd.log' ...\r"
        sudo rm -f /var/log/webcamd.log > /dev/null
        if [[ -f "${HOME}/klipper_logs/webcamd.log" ]]; then
        sudo rm -f "${HOME}"/klipper_logs/webcamd.log > /dev/null
        fi
        if [[ -f "${HOME}/printer_data/logs/webcamd.log" ]]; then
        sudo rm -f "${HOME}"/printer_data/logs/webcamd.log > /dev/null
        fi
        echo -e "Removing 'webcamd.log' ... \t[${CN_OK}]\r"
    fi
    if [[ -f "/etc/logrotate.d/webcamd" ]]; then
        echo -en "Removing 'webcamd' logrotate...\r"
        sudo rm -f /etc/logrotate.d/webcamd > /dev/null
        echo -e "Removing 'webcamd' logrotate ... \t[${CN_OK}]\r"
    fi
    echo -e "\nOld 'webcamd' completly removed."
    echo -e "webcam.txt kept,but no longer necessary ..."
}

install_packages() {
    ### Crowsnest Dependencies
    PKGLIST="git crudini bsdutils findutils v4l-utils curl"
    ### Ustreamer Dependencies
    PKGLIST="${PKGLIST} build-essential libevent-dev libjpeg-dev libbsd-dev"
    ### simple-rtsp-server Dependencies
    PKGLIST="${PKGLIST} libxcomposite1 libxtst6 ffmpeg"

    echo -e "Running apt update first ..."
    ### Run apt update
    sudo apt-get -q --allow-releaseinfo-change update

    echo -e "Installing 'crowsnest' Dependencies ..."
    # shellcheck disable=SC2086
    # disable because we want 'wordsplitting'
    sudo apt-get install -q -y --no-install-recommends ${PKGLIST}

    if [[ "$(get_os_version buster)" != "0" ]] && [[ "$(is_raspberry_pi)" = "1" ]]; then
        sudo apt-get install -q -y --no-install-recommends libraspberrypi-dev
    fi
    echo -e "Installing 'crowsnest' Dependencies ... [${CN_OK}]"
}

install_crowsnest() {
    local bin_path config config_log_path crowsnest_bin
    bin_path="/usr/local/bin"
    config="${CROWSNEST_CONFIG_PATH}/crowsnest.conf"
    crowsnest_bin="/home/${BASE_USER}/crowsnest/crowsnest"
    # Link crowsnest to $PATH
    echo -en "Linking crowsnest ...\r"
    # Remove if exist!
    if [[ -f /usr/local/bin/crowsnest ]]; then
        rm -f /usr/local/bin/crowsnest
    fi
    sudo ln -sf "${crowsnest_bin}" "${bin_path}" > /dev/null
    echo -e "Linking crowsnest ... [${CN_OK}]\r"
    # Install base line config
    if [[ -f "${config}" ]]; then
        echo -e "Found existing 'crowsnest.conf' in ${CROWSNEST_CONFIG_PATH}"
        echo -e "Checking log_path ..."
        config_log_path="$(crudini --get "${config}" crowsnest log_path)"
        # strip out file name (crowsnest.log)
        if [[ "${config_log_path%/*.*}" != "${CROWSNEST_LOG_PATH}" ]]; then
            echo -e "Setup new log_path: ${CROWSNEST_LOG_PATH}"
            sed -i 's|'"${config_log_path}"'|'"${CROWSNEST_LOG_PATH}/crowsnest.log"'|' "${config}"
            # Strip full path to tilde
            sed -i 's|'"/home/${BASE_USER}"'|~|g' "${config}"
        fi
        if [[ "${config_log_path%/*.*}" = "${CROWSNEST_LOG_PATH}" ]]; then
            echo -e "Entry matching ... [${CN_OK}]"
            # Strip full path to tilde
            sed -i 's|'"/home/${BASE_USER}"'|~|g' "${config}"
        fi
    fi
    # Make sure not overwrite existing!
    if [[ ! -f "${config}" ]]; then
        echo -en "Copying crowsnest.conf ...\r"
        sudo -u "${BASE_USER}" \
        cp -f "${CROWSNEST_DEFAULT_CONF}" "${config}" &> /dev/null
        sed -i 's|%LOGPATH%|'"${CROWSNEST_LOG_PATH}/crowsnest.log"'|g' "${config}"
        # Strip full path to tilde
        sed -i 's|'"/home/${BASE_USER}"'|~|g' "${config}"
        echo -e "Copying crowsnest.conf ... [${CN_OK}]\r"
    fi
    return 0
}

install_service_file() {
    local servicefile systemd_dir
    servicefile="${PWD}/resources/crowsnest.service"
    systemd_dir="/etc/systemd/system"
    echo -en "Install crowsnest.service file ...\r"
    # Install Service file
    cp -f "${servicefile}" "${systemd_dir}"
    sed -i 's|%USER%|'"${BASE_USER}"'|g;s|%ENV%|'"${CROWSNEST_ENV_PATH}/crowsnest.env"'|g' \
    "${systemd_dir}/crowsnest.service"
    # create and install env file
    echo -e "CROWSNEST_ARGS=\"-c ${CROWSNEST_CONFIG_PATH}/crowsnest.conf\"\n" > "${CROWSNEST_ENV_PATH}/crowsnest.env"
    chown -f "${BASE_USER}":"${BASE_USER}" "${CROWSNEST_ENV_PATH}/crowsnest.env"
    echo -e "Install crowsnest.service file ... [${CN_OK}]\r"
}

install_logrotate() {
    local logrotatefile logpath
    logrotatefile="resources/logrotate_crowsnest"
    logpath="${CROWSNEST_LOG_PATH}/crowsnest.log"
    # install logrotate
    echo -en "Install logrotate file ...\r"
    cp -rf "${logrotatefile}" /etc/logrotate.d/crowsnest
    sed -i 's|%LOGPATH%|'"${logpath}"'|g' /etc/logrotate.d/crowsnest
    echo -e "Install logrotate file ... [${CN_OK}]\r"
}

add_update_entry() {
    local moonraker_conf
    moonraker_conf="${CROWSNEST_CONFIG_PATH}/moonraker.conf"
    moonraker_update="${PWD}/resources/moonraker_update.txt"
    echo -en "Adding Crowsnest Update Manager entry to moonraker.conf ...\r"
    if [[ -f "${moonraker_conf}" ]]; then
        if [[ "$(grep -c "crowsnest" "${moonraker_conf}")" != "0" ]]; then
            echo -e "Update Manager entry already exists moonraker.conf ... [${CN_SK}]"
            return 0
        fi
        # make sure no file exist
        if [[ -f "/tmp/moonraker.conf" ]]; then
            sudo rm -f /tmp/moonraker.conf
        fi
        sudo -u "${BASE_USER}" \
        cp "${moonraker_conf}" "${moonraker_conf}.backup" &&
        cat "${moonraker_conf}" "${moonraker_update}" > /tmp/moonraker.conf &&
        cp -rf /tmp/moonraker.conf "${moonraker_conf}"
        if [[ "${CROWSNEST_UNATTENDED}" = "1" ]]; then
            sudo rm -f "${moonraker_conf}.backup"
        fi
        echo -e "Adding Crowsnest Update Manager entry to moonraker.conf ... [${CN_OK}]"
    else
        echo -e "moonraker.conf is missing ... [${CN_SK}]"
    fi
}

## add $USER to group video
add_group_video() {
    echo -en "Add User ${BASE_USER} to group 'video' ...\r"
    if [[ "$(groups "${BASE_USER}" | grep -c video)" == "0" ]]; then
        usermod -aG video "${BASE_USER}" > /dev/null
        echo -e "Add User ${BASE_USER} to group 'video' ... [${CN_OK}]"
    else
        echo -e "Add User ${BASE_USER} to group 'video' ... [${CN_SK}]"
        echo -e "==> User ${BASE_USER} is already in group 'video'"
    fi
}

clone_ustreamer() {
    ## remove bin/ustreamer if exist
    if [[ -d bin/ustreamer ]]; then
        rm -rf bin/ustreamer
    fi
    sudo -u "${BASE_USER}" \
    git clone "${CROWSNEST_USTREAMER_REPO_SHIP}" \
    -b "${CROWSNEST_USTREAMER_REPO_BRANCH}" bin/ustreamer
    ## Buster workaround
    ## ustreamer support omx only till version 4.13
    ## so stick to that version
    if [[ "$(get_os_version buster)" != "0" ]]; then
        pushd bin/ustreamer &> /dev/null || exit 1
        git reset --hard 61ab2a8
        popd &> /dev/null || exit 1
    fi
}

build_apps() {
    echo -e "Build dependend Stream Apps ..."
    echo -e "Cloning ustreamer repository ..."
    clone_ustreamer
    pushd bin > /dev/null
    sudo -u "${BASE_USER}" make all
    popd > /dev/null
}

is_raspberry_pi() {
    if [[ -f /proc/device-tree/model ]] &&
    grep -q "Raspberry" /proc/device-tree/model; then
        echo "1"
    else
        echo "0"
    fi
}

install_raspicam_fix() {
    if [[ "${CROWSNEST_RASPICAMFIX}" == "auto" ]]; then
        if [[ "$(is_raspberry_pi)" = "1" ]]; then
            echo -e "Device is a Raspberry Pi"
            CROWSNEST_RASPICAMFIX="1"
        fi
        if [[ "$(is_raspberry_pi)" = "0" ]]; then
            echo -e "Device is \e[31mNOT\e[0m a Raspberry Pi ... [${CN_SK}]"
            CROWSNEST_RASPICAMFIX="0"
        fi
    fi
    if [[ "${CROWSNEST_RASPICAMFIX}" == "1" ]]; then
        echo -en "Applying Raspicam Fix ... \r"
        bash -c 'echo "bcm2835-v4l2" >> /etc/modules'
        cp resources/bcm2835-v4l2.conf /etc/modprobe.d/
        echo -e "Applying Raspicam Fix ... [${CN_OK}]"
    fi
}

enable_legacy_cam() {
    local cfg
    local -a model
    cfg="/boot/config.txt"
    model=(pi3 pi4)
    if [[ -f "${cfg}" ]] && [[ "$(is_raspberry_pi)" = "1" ]]; then

        # Helper func
        get_val() {
            crudini --get "${cfg}" "${1}" gpu_mem 2> /dev/null
        }

        echo -en "Enable legacy camera stack ... \r"
        sed -i "s/camera_auto_detect=1/#camera_auto_detect=1/" "${cfg}"
        if [[ "$(grep -c "start_x" "${cfg}")" = "0" ]]; then
            crudini --set --inplace "${cfg}" all start_x 1 &> /dev/null
        fi

        for d in "${model[@]}"; do
            if [[ "$(get_val "${d}")" -lt "129" ]]; then
                crudini --set --inplace "${cfg}" "${d}" gpu_mem 256 &> /dev/null
            fi
        done
        if [[ "$(get_val pi0)" -lt "129" ]]; then
                sudo crudini --set --inplace "${cfg}" pi0 gpu_mem 160 &> /dev/null
        fi
        echo -e "Enable legacy camera stack ... [${CN_OK}]"
    fi
}

## Ubuntu on RPI Workaround
## Using seperate function to not distract existing behavior

enable_buntu_cam() {
    local cfg
    local -a model
    cfg="$(find /boot/ -type f -name "config.txt" -printf "%p\n")"
    model=(pi3 pi4)
    if [[ -f "${cfg}" ]]; then

        # Helper func
        get_val() {
            crudini --get "${cfg}" "${1}" gpu_mem 2> /dev/null
        }

        echo -en "Enable legacy camera stack ... \r"
        sed -i "s/camera_auto_detect=1/#camera_auto_detect=1/" "${cfg}"
        if [[ "$(grep -c "start_x" "${cfg}")" = "0" ]]; then
            crudini --set --inplace "${cfg}" all start_x 1 &> /dev/null
        fi

        for d in "${model[@]}"; do
            if [[ "$(get_val "${d}")" -lt "129" ]]; then
                crudini --set --inplace "${cfg}" "${d}" gpu_mem 256 &> /dev/null
            fi
        done
        if [[ "$(get_val pi0)" -lt "129" ]]; then
                sudo crudini --set --inplace "${cfg}" pi0 gpu_mem 160 &> /dev/null
        fi
        echo -e "Enable legacy camera stack ... [${CN_OK}]"
    fi
}

## enable service
enable_service() {
    echo -en "Enable crowsnest.service on boot ...\r"
    sudo systemctl enable crowsnest.service &> /dev/null
    echo -e "Enable crowsnest.service on boot ... [${CN_OK}]\r"
}

## start systemd service
start_service() {
        sudo systemctl daemon-reload &> /dev/null
        sudo systemctl start crowsnest.service &> /dev/null
}

## ask reboot
ask_reboot() {
    local reply
    while true; do
        read -erp "Reboot NOW? [y/N]: " -i "N" reply
        case "${reply}" in
            [yY]*)
                echo -e "Going to reboot in 5 seconds!"
                sleep 5
                reboot
            ;;
            [nN]*)
                echo -e "\n\e[31mNot to reboot may cause issues!"
                echo -e "Reboot as soon as possible!\e[0m\n"
                echo -e "Goodbye ..."
                break
            ;;
            * )
                    echo -e "\e[31mERROR:\e[0m Please choose Y or N !"
            ;;
        esac
    done
}

## Main func
main() {
    ## Initialize traps
    install_cleanup_trap

    ## Welcome message
    welcome_msg

    ## Step 1: import .config file
    if [[ "${CROWSNEST_UNATTENDED}" = "0" ]]; then
        import_config
    fi

    ## Make sure folders exist
    create_filestructure

    ## Step 2: Detect existing webcamd
    if [[ "${CROWSNEST_UNATTENDED}" = "0" ]]; then
        detect_existing_webcamd
    fi

    ## Step 3: Install dependencies
    install_packages

    ## Step 4: Install crowsnest
    install_crowsnest

    ## Step 5: Build Applications
    build_apps

    ## Step 6: Add $USER to group 'video'
    add_group_video

    ## Step 7: Enable Legacy Camera Stack
    if [[ "$(get_os_version bullseye)" != "0" ]] &&
    [[ -f "/boot/config.txt" ]]; then
        enable_legacy_cam
    fi

    ### buntu workaround
    ### see L#422
    if [[ "$(get_os_version buntu)" != "0" ]] &&
    [[ "$(is_raspberry_pi)" = "1" ]]; then
        enable_buntu_cam
    fi

    ## Step 8: Install service File
    install_service_file

    ## Step 9: Enable service
    ## If unattended skip enable and start service
    if [[ -f /etc/systemd/system/crowsnest.service ]] &&
    [[ "${CROWSNEST_UNATTENDED}" = "0" ]]; then
        enable_service
    fi
    if [[ "${CROWSNEST_UNATTENDED}" = "0" ]]; then
        start_service
    fi

    ## Step 10: Install logrotate file
    install_logrotate

    ## Step 11: Install raspicamfix
    install_raspicam_fix

    ## Step 12: Add moonraker update_manager entry
    if [[ "${CROWSNEST_UNATTENDED}" = "1" ]] ||
    [[ "${CROWSNEST_ADD_CROWSNEST_MOONRAKER}" = "1" ]]; then
        add_update_entry
    fi

    ## Step 13: Ask for reboot
    ## Skip if UNATTENDED
    goodbye_msg
    if [[ "${CROWSNEST_UNATTENDED}" = "0" ]]; then
        ask_reboot
    fi
}

main
exit 0
