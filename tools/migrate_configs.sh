#!/usr/bin/env bash

#### crowsnest - A webcam Service for multiple Cams and Stream Services.
####
#### Written by Patrick Gehrsitz aka mryel00 <mryel00.github@gmail.com>
#### Copyright 2026 - till today
#### https://github.com/mainsail-crew/crowsnest
####
#### This File is distributed under GPLv3
####

set -e

# --- Configuration ---
CROWSNEST_CFG_NAME="crowsnest.conf"
MOONRAKER_CFG_NAME="moonraker.conf"

# --- Functions ---

log_info() {
    echo -e "\e[32m[INFO]\e[0m $1" >&2
}

log_warn() {
    echo -e "\e[33m[WARN]\e[0m $1" >&2
}

log_error() {
    echo -e "\e[31m[ERROR]\e[0m $1" >&2
}

find_config() {
    if systemctl cat crowsnest.service >/dev/null 2>&1; then
        local service_content
        service_content=$(systemctl cat crowsnest.service)

        local env_file_path
        env_file_path=$(echo "$service_content" | grep "^EnvironmentFile=" | cut -d= -f2)

        if [[ -n "${env_file_path}" && -f "${env_file_path}" ]]; then
            local args_line
            args_line=$(grep "^CROWSNEST_ARGS=" "${env_file_path}")

            if [[ -n "${args_line}" ]]; then
                local extracted_path
                if [[ $args_line =~ -c[[:space:]]+([^[:space:]\"]+) ]]; then
                     extracted_path="${BASH_REMATCH[1]}"
                fi

                if [[ -n "${extracted_path}" && -f "${extracted_path}" ]]; then
                    echo "${extracted_path}"
                    return 0
                fi
            fi
        fi
    fi

    local base_user
    if [[ -n "${SUDO_USER}" ]]; then
        base_user="${SUDO_USER}"
    else
        base_user="$(whoami)"
    fi
    local user_home
    user_home="/home/${base_user}"

    local found_config
    found_config=$(find "${user_home}" -maxdepth 4 -type d -name "crowsnest" -prune -o -type f -name "${CROWSNEST_CFG_NAME}" -print | head -n 1)

    if [[ -n "${found_config}" ]]; then
        echo "${found_config}"
        return 0
    fi

    log_error "Could not find ${CROWSNEST_CFG_NAME} in ${user_home} or an installed crowsnest.service."
    log_error "Skipping crowsnest.conf backup."
    return 1
}

backup_config() {
    local extension
    local cfg="$1"
    local mr_cfg="$2"
    extension="$(date +%Y-%m-%d-%H%M)"
    cp "${cfg}" "${cfg}.${extension}"
    cp "${mr_cfg}" "${mr_cfg}.${extension}.bkp"
}

migrate_crudini() {
    local crowsnest_cfg="$1"
    local val

    log_info "Using crudini for migration..."

    while IFS= read -r section; do
        if [[ "$section" != "crowsnest" ]] && [[ ! "$section" =~ ^cam\ .* ]]; then
            log_info "Removing unknown section: [${section}]"
            crudini --del "${crowsnest_cfg}" "${section}"
            continue
        fi

        if [[ "$section" == "crowsnest" ]]; then
            if crudini --get "${crowsnest_cfg}" "${section}" "log_path" >/dev/null 2>&1; then
                log_info "Removing log_path from [crowsnest]"
                crudini --del "${crowsnest_cfg}" "${section}" "log_path"
            fi
        fi

        if [[ "$section" =~ ^cam\ .* ]]; then
            if crudini --get "${crowsnest_cfg}" "${section}" "enable_rtsp" >/dev/null 2>&1; then
                log_info "Removing enable_rtsp from [${section}]"
                crudini --del "${crowsnest_cfg}" "${section}" "enable_rtsp"
            fi

            if crudini --get "${crowsnest_cfg}" "${section}" "rtsp_port" >/dev/null 2>&1; then
                log_info "Removing rtsp_port from [${section}]"
                crudini --del "${crowsnest_cfg}" "${section}" "rtsp_port"
            fi

            if val=$(crudini --get "${crowsnest_cfg}" "${section}" "mode" 2>/dev/null); then
                val=$(echo "$val" | sed 's/[#;].*//' | xargs)
                if [[ "$val" != "ustreamer" ]] && [[ "$val" != "camera-streamer" ]] && [[ "$val" != "spyglass" ]]; then
                    log_info "Updating invalid mode '$val' to 'ustreamer' in [${section}]"
                    crudini --set "${crowsnest_cfg}" "${section}" "mode" "ustreamer"
                fi
            fi
        fi
    done < <(crudini --get --list "${crowsnest_cfg}")

    log_info "Migrate delete_log option with sed..."
    sed -i -E 's/delete_log:[[:space:]]*([^ #]*).*/rollover_on_start: \1                # Creates a backup and clears the log on every restart, if set to true/' "${crowsnest_cfg}"
    sed -i -E 's/(mode:[[:space:]]*[^ #]*[[:space:]]*).*/\1# https:\/\/docs.mainsail.xyz\/crowsnest\/faq\/backends/' "${crowsnest_cfg}"
    sed -i -E '/[[:space:]]*# camera-streamer - Provides WebRTC, MJPG and snapshots.*/d' "${crowsnest_cfg}"
}

cleanup_legacy_comments() {
    local cfg="$1"
    log_info "Cleaning up legacy RTSP comments..."
    sed -i '/RTSP Stream URL:/,/^##*$/d' "${cfg}"
}

cleanup_moonraker_config() {
    local cfg="$1"
    log_info "Cleaning up moonraker.conf entries..."
    crudini --del "${cfg}" "update_manager crowsnest"
    sed -i '/# Crowsnest update_manager entry/d' "${cfg}"
}

CROWSNEST_CFG_PATH=$(find_config) || exit 1
MOONRAKER_CFG_PATH="${CROWSNEST_CFG_PATH%"$CROWSNEST_CFG_NAME"}${MOONRAKER_CFG_NAME}"
MIGRATED_TEMP="${CROWSNEST_CFG_PATH}.v5"

if ! command -v crudini >/dev/null 2>&1; then
    log_error "crudini is required but not found. If it isn't installed, you most likely don't need to run this script."
    exit 1
fi

log_info "Found config at: ${CROWSNEST_CFG_PATH}"

backup_config "${CROWSNEST_CFG_PATH}" "${MOONRAKER_CFG_PATH}"
migrate_crudini "${CROWSNEST_CFG_PATH}" "${MOONRAKER_CFG_PATH}"
cleanup_legacy_comments "${CROWSNEST_CFG_PATH}"
cleanup_moonraker_config "${MOONRAKER_CFG_PATH}"

mv "${CROWSNEST_CFG_PATH}" "${MIGRATED_TEMP}"

log_info "Migration complete."

echo "${MIGRATED_TEMP}"
