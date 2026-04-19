#!/usr/bin/env bash

#=======================================================================#
# Copyright (C) 2020 - 2024 Dominik Willner <th33xitus@gmail.com>       #
#                                                                       #
# This file may be distributed under the terms of the GNU GPLv3 license #
#=======================================================================#

#=======================================================================#
# Crowsnest Installer brought to you by KwadFan <me@stephanwe.de>       #
# Copyright (C) 2022 KwadFan <me@stephanwe.de>                          #
# https://github.com/KwadFan/crowsnest                                  #
#=======================================================================#

# This file is created from code snippets of https://github.com/dw-0/kiauh/tree/v5
# and slightly adjusted to fit into Crowsnest

# Exit on errors
set -Ee

check_multi_instance(){
  local -a instances
  readarray -t instances < <(find "/home/${BASE_USER}" -regex "/home/${BASE_USER}/[a-zA-Z0-9_]+_data/*" -printf "%P\n" 2> /dev/null | sort)
  if [[ "${#instances[@]}" -gt 1 ]]; then
    msg "Multi instance install detected ..."
    multi_instance_message "${instances[*]}"
    if [[ -d "/home/${BASE_USER}/crowsnest" ]]; then
      pushd "/home/${BASE_USER}/crowsnest" &> /dev/null || exit 1
      if ! sudo -u "${BASE_USER}" make config ;then
        msg "Something went wrong! Please try again..."
        if [[ -f "${SRC_DIR}/.config" ]]; then
          rm -f "${SRC_DIR}/.config"
        fi
        exit 1
      fi
      if [[ ! -f "${SRC_DIR}/.config" ]]; then
        msg "failure while generating .config"
        msg "Generating .config failed, installation aborted"
        exit 1
      fi
      popd &> /dev/null || exit 1
    fi
  fi
}

multi_instance_message(){
  echo -e "Crowsnest is NOT designed to support multi instances."
  echo -e "A workaround for this is to choose the most used instance as a 'master'"
  echo -e "Use this instance to set up your 'crowsnest.conf' and steering it's service.\n"
  echo -e "Found the following instances:\n"
  for i in ${1}; do
    select_msg "${i}"
  done
  echo -e "\nLaunching crowsnest's configuration tool ..."
  continue_config
}

select_msg() {
  echo -e "   [➔] ${1}"
}

continue_config() {
  local reply
  while true; do
    read -erp "###### Continue with configuration? (y/N): " reply
    case "${reply}" in
      Y|y|Yes|yes)
        select_msg "Yes"
        break;;
      N|n|No|no|"")
        select_msg "No"
        msg "Installation aborted by user ... Exiting!"
        exit 1;;
      *)
        msg "Invalid Input!\n";;
    esac
  done
}
