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

### Disable SC2317
# shellcheck disable=SC2317

# Exit on errors
set -Ee

# Debug
# set -x

# Global Vars
TITLE="\e[31mcrowsnest\e[0m - $(basename "${0}")"
DH_VERSION="v0.0.0"
[[ -n "${BASE_USER}" ]] || BASE_USER="$(logname)"

# Set fallback lang
export LC_ALL=C

# Message Vars
CN_OK="\e[32mOK\e[0m"
CN_FL="\e[31mFAILED\e[0m"
# leave in place for later use
# CN_SK="\e[33mSKIPPED\e[0m"

CN_G="\e[32m"
CN_R="\e[31m"
CN_B="\e[34m"
CN_N="\e[0m"


# Message funcs
echo_green() {
    echo -e "\e[32m${1}\e[0m"
}

echo_red() {
    echo -e "\e[31m${1}\e[0m"
}

echo_yellow() {
    echo -e "\e[33m${1}\e[0m"
}

echo_blue() {
    echo -e "\e[34m${1}\e[0m"
}

echo_blank() {
    echo -e "\n"
}

help_msg() {
    echo -e "\n\t $(basename "${0}") [Options]\n"
    echo -e "\t\t-h\tPrints this help."
    echo -e "\t\t-V\tShows Version of $(basename "${0}")"
    echo -e "\t\t-a\tShows all available informations gathered"
    echo -e "\t\t-c\tShows informations about cameras"
    echo -e "\t\t-o\tShows informations about used OS"
    echo -e "\t\t-s\tShows informations about host system"
    echo -e "\t\t-x\tPerforms tests to ensure successful install of crowsnest"
    echo -e "\t\t-d\tDecolorize file (if output is redirected to file)"
    echo_blank
    exit 1
}

# Global functions

## call get_os_version <keyword>
get_os_info() {
    local osrel adrel
    # Dirty Hack to not fail script :P
    adrel="$(find /etc -name "*-release" -type f -print 2> /dev/null || echo "" )"
    if [[ -f /etc/os-release ]]; then
        osrel="$(grep "PRETTY_NAME=" /etc/os-release | cut -d'=' -f2 | sed 's/\"//g')"
        echo_blue "OS Info:\n"
        echo -e "Distribution: ${CN_G}\t${osrel}${CN_N}\n"
    fi
    ## Find additional informations
    if [[ -n "${adrel}" ]]; then
        for i in ${adrel}; do
            if [[ -f "${i}" ]]; then
                echo_blue "Additional Release Info:\n"
                echo -e "From ${i}:\n"
                echo -e "${CN_G}$(cat "${i}")${CN_N}\n"
            fi
        done
    fi
}

### Import config
import_config() {
    ## Source config if present
    if [[ -s tools/.config ]]; then
        # shellcheck disable=SC1091
        source tools/.config
        return 0
    else
        echo -e "\[31mNo .config found!\e[0m"
        return 0
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

# get_val <pathtocfg> <section> <parameter>
# spits out value
get_val() {
    crudini --get "${1}" "${2}" "${3}" 2> /dev/null
}

host_info() {
    grep "model name" /proc/cpuinfo | head -1 | awk -F': ' '{print $2}'
}

load_avg() {
    local load_avg
    load_avg=$(uptime | rev | cut -d":" -f1 | rev | sed 's/ //1' )
    echo "  ${load_avg} (load in last 1m/5m/15m)"
}

cpu_info() {
    if [[ -n "$(command -v lscpu)" ]]; then
        echo_blue "CPU Details:\n"
        lscpu
        echo_blank
    fi
}

mem_info() {
    echo_blue "Mem Info:"
    free -m
    echo -e "\n"
}

disk_info() {
    echo_blue "Disk Info:"
    df -h /
    echo -e "\n"
}

get_host_info() {
        local kernel model
        kernel="$(uname -srmp)"
        echo_blue "Host Informations:\n"
        if [[ -f /proc/device-tree/model ]]; then
            model="$(tr -d '\0' < /proc/device-tree/model)"
        fi
        if [[ ! -f /proc/device-tree/model ]]; then
            model="${CN_R}Unknown ($(host_info))${CN_N}"
        fi
        echo -e "Running on: ${CN_G}${model}${CN_N}\n"
        echo -e "Kernel: ${CN_G}${kernel}${CN_N}\n"
        echo -e "Load Average: $(load_avg)\n"
        cpu_info
        mem_info
        disk_info
}

get_cam_info() {
    local cam ctrls vid_dev
    vid_dev="$(find /dev/v4l/by-path -name "*video*index0" -print | sed '/isp/d;/codec/d' )"
    if [[ -z "$(command -v v4l2-ctl)" ]]; then
        echo_red "Command: v4l2-ctl not found!"
        echo_red "Can not grab appropriate informations ..."
        return 0
    fi
    ## helper func
    sym_lnk() {
        local dev
        dev="$(basename "$(readlink -f "${1}")")"
        find /dev/v4l -type l -ls | grep -i "${dev}$" | awk '{print $11}'
    }

    echo_blue "v4l2-ctl supported camera(s):\n"
    for dev in ${vid_dev}; do
        cam="$(v4l2-ctl -d "${dev}" --list-formats-ext | sed '1,3d')"
        ctrls="$(v4l2-ctl -d "${dev}" --list-ctrls-menus || echo "")"
        echo_blue "Device $(readlink -f "${dev}"):\n"
        echo_green "Symbolic links to $(readlink -f "${dev}"):\n"
        sym_lnk "${dev}"
        echo_blank
        echo -e "Supported formats:\n"
        echo -e "${cam}\n"
        if [[ -n "${ctrls}" ]]; then
            echo -e "Supported Controls:\n"
            echo -e "${ctrls}\n"
        fi
    done
}

get_crowsnest() {
    local cn_bin cn_svc_file
    cn_bin="$(command -v crowsnest)"
    cn_svc_file="$(find /etc/systemd/system -maxdepth 1 -name "crowsnest*.service")"
    echo_blue "Testing install of crowsnest:\n"
    echo_green "Some tests need 'sudo' rights!\nPlease enter password if prompted!\n"
    sudo sh -c 'echo "" > /dev/null'
    echo -e "Searching for crowsnest ..."
    if [[ -n "${cn_bin}" ]]; then
        echo -e "crowsnest found in ${cn_bin} [${CN_OK}]"
        echo -e "\t${CN_B}==>${CN_N} $(readlink -f "${cn_bin}")\n"
        echo_blue "Version:"
        crowsnest -v
        echo_blank
    else
        echo -e "crowsnest not found! [${CN_FL}]\n"
        echo_red "Further test will be aborted...\n"
        exit 1
    fi
    echo_blue "Service tests:\n"
    for svc in ${cn_svc_file}; do
        if [[ ! -f "${svc}" ]]; then
        echo -e "${svc} not found! [${CN_FL}]\n"
        fi
        if [[ -f "${svc}" ]]; then
        echo -e "${svc} found! [${CN_OK}]\n"
        ## Print service file
        echo_blue "Print service file:\n"
        cat -n "${svc}"
        echo_blank
        fi
        ## Check is-active
        echo -e "Service Status: ${CN_G}$(sudo systemctl is-active "$(basename "${svc}")")${CN_N}\n"
        ## Check for env file
        cn_env_path="$(grep -i "EnvironmentFile" "${svc}" | cut -d"=" -f2)"
        echo_blue "Environment file ($(basename "${cn_env_path}")):"
        if [[ ! -f "${cn_env_path}" ]]; then
            echo -e "${cn_env_path} not found! [${CN_FL}]\n"
        fi
        if [[ -f "${cn_env_path}" ]]; then
            echo -e "${cn_env_path} found! [${CN_OK}]\n"
            echo_blue "Print environment file:\n"
            cat -n "${cn_env_path}"
            echo_blank
        fi
        ## Check config file
        ### Import path from env file
        # shellcheck disable=SC1090
        . "${cn_env_path}"
        cn_cnf_path="${CROWSNEST_ARGS/-c /}"
        echo_blue "Config file ($(basename "${cn_cnf_path}")):"
        if [[ ! -f "${cn_cnf_path}" ]]; then
            echo -e "${cn_cnf_path} not found! [${CN_FL}]\n"
        fi
        if [[ -f "${cn_cnf_path}" ]]; then
            echo -e "${cn_cnf_path} found! [${CN_OK}]\n"
            echo_blue "Print config file:\n"
            cat -n "${cn_cnf_path}"
            echo_blank
        fi
        ## Check log file
        ### Clean path
        cn_log_path="$(grep -i "crowsnest.log" "${cn_cnf_path}" | sed 's#log_path: ~#'"${HOME}"'#')"
        echo_blue "Log file ($(basename "${cn_log_path}")):"
        if [[ ! -f "${cn_log_path}" ]]; then
            echo -e "${cn_log_path} not found! [${CN_FL}]\n"
        fi
        if [[ -f "${cn_log_path}" ]]; then
            echo -e "${cn_log_path} found! [${CN_OK}]\n"
            echo_blue "Print config file (last 10 lines):\n"
            tail -n10 "${cn_log_path}"
            echo_blank
        fi
    done
}

get_config() {
    echo_blue "Installer .config file ($(basename "${cn_cnf_file}")):"
    cn_cnf_file="${PWD}/tools/.config"
    if [[ ! -f "${cn_cnf_file}" ]]; then
        echo -e "${cn_cnf_file} not found! [${CN_FL}]\n"
    fi
    if [[ -f "${cn_cnf_file}" ]]; then
        echo -e "${cn_cnf_file} found! [${CN_OK}]\n"
        echo_blue "Print .config file:\n"
        cat -n "${cn_cnf_file}"
        echo_blank
    fi
}

decolorize() {
    echo -en "Decolorizing ${1} ...\r"
    sed -r -i 's/\x1B\[([0-9]{1,3}(;[0-9]{1,2})?)?[mGK]//g' "${1}"
    echo -e "Decolorizing ${1} ...[${CN_OK}]\r"
    echo_blank
}

#### MAIN
echo -e "${TITLE}\n"
[[ "${#}" -eq 0 ]] && help_msg
while getopts ":acd:hosxzV" arg; do
        case "${arg}" in
            a )
                get_os_info
                get_host_info
                get_cam_info
                get_crowsnest
                get_config
                break
            ;;
            c )
                get_cam_info
                break
            ;;
            d )
                decolorize "${OPTARG}"
                break
            ;;
            o )
                get_os_info
                break
            ;;
            s )
                get_host_info
                break
            ;;
            x )
                get_crowsnest
                break
            ;;
            z )
                get_config
                break
            ;;
            V )
                echo -e "${CN_B}$(basename "${0}")${CN_N} Version: ${CN_G}${DH_VERSION}${CN_N}\n"
                break
            ;;
            h | \? )
                echo -e "Invalid option: -${OPTARG}"
                help_msg
            ;;
        esac
    done

exit 0
