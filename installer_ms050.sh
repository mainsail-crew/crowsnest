#!/bin/bash

set -e
# set -x
export DEBIAN_FRONTEND=noninteractive


if [ "${UID}" == "0" ]; then
    echo -e "\nDO NOT RUN THIS SCRIPT AS 'root' !!!\n"
    exit 1
fi
echo -e "Some Commands have to run as 'root' via sudo."
echo -e "You will be asked for password if needed.\n"

# Stoping existing Daemon
echo -e "Stopping existing webcamd...\n"
sudo systemctl stop webcamd

# Remove existing webcamd.
echo -e "Backup existing files...\n"
mkdir -p ${HOME}/webcamd-backup
if [ -e "/etc/systemd/system/webcamd.service" ]; then
    cp -p /etc/systemd/system/webcamd.service ${HOME}/webcamd-backup
fi
if [ -e "/usr/local/bin/webcamd" ]; then
    cp -p /usr/local/bin/webcamd ${HOME}/webcamd-backup/
fi
if [ -e "/etc/logrotate.d/webcamd" ]; then
    cp -p /etc/logrotate.d/webcamd ${HOME}/webcamd-backup/webcamd.logrotate
fi

# Remove existing.
echo -e "Removing existing webcamd...\n"
sudo rm -rf /etc/logrotate.d/webcamd
sudo rm -rf /usr/local/bin/webcamd
sudo rm -rf /etc/systemd/system/webcamd.service
sudo rm -rf ${HOME}/klipper_logs/webcamd.log
sudo rm -rf /var/log/webcamd.log

# Install Dependency
sudo apt update
sudo apt install crudini -y

# Install Project "crowsnest"
echo -e "Installing webcamd and enable Service"
sudo ln -s $PWD/webcamd /usr/local/bin/webcamd
sudo cp -r $PWD/file_templates/webcamd.service /etc/systemd/system/
cp -r $PWD/sample_configs/minimal.conf ${HOME}/klipper_config/webcam.conf
sudo systemctl daemon-reload
sudo systemctl enable webcamd


# Install ustreamer
# Make sure its clean
if [ -d "${HOME}/ustreamer" ]; then
    rm -rf ${HOME}/ustreamer/
fi

echo -e "Compiling ustreamer..."
cd ~
git clone https://github.com/pikvm/ustreamer.git
cd ustreamer
if [[ "$(cat /proc/device-tree/model | cut -d ' ' -f1)" = "Raspberry" ]]; then
    sudo apt update
    sudo apt install build-essential libevent-dev libjpeg-dev libbsd-dev \
    libraspberrypi-dev libgpiod-dev -y
    export WITH_OMX=1
    make -j $(nproc) # push limit
    echo -e "Create symlink..."
    sudo ln -sf ${HOME}/ustreamer/ustreamer /usr/local/bin/
else
    sudo apt update
    sudo apt install build-essential libevent-dev libjpeg-dev libbsd-dev \
    libgpiod-dev -y
    make -j $(nproc)
    echo -e "Create symlink..."
    sudo ln -sf ${HOME}/ustreamer/ustreamer /usr/local/bin/
fi

# Install v4l2rtspserver
# Make sure its clean
if [ -d "${HOME}/v4l2rtspserver" ]; then
    rm -rf ${HOME}/v4l2rtspserver/
fi
echo -e "Compiling v4l2rtspserver..."
cd ~
git clone https://github.com/mpromonet/v4l2rtspserver.git
cd v4l2rtspserver
sudo apt install cmake liblivemedia-dev liblog4cpp5-dev -y
cmake . && make -j $(nproc) # push limit
echo -e "Create symlink..."
sudo ln -sf ${HOME}/v4l2rtspserver/v4l2rtspserver /usr/local/bin/

# create mjpg_streamer symlink
echo -e "Create mjpg_streamer symlink..."
sudo ln -sf ${HOME}/mjpg-streamer/mjpg_streamer /usr/local/bin/

# Start webcamd
sudo sh -c "echo bcm2835-v4l2 >> /etc/modules"
sudo systemctl start webcamd


# webcamd to moonraker.conf
echo -e "Adding update manager to moonraker.conf"

update_section=$(grep -c '\[update_manager webcamd\]' \ 
${HOME}/klipper_config/moonraker.conf)
if [ "${update_section}" -eq 0 ]; then
  echo -e "\n" >> ${HOME}/klipper_config/moonraker.conf
  while read -r line; do
    echo -e "${line}" >> ${HOME}/klipper_config/moonraker.conf
  done < "$PWD/file_templates/moonraker_update.txt"
  echo -e "\n" >> ${HOME}/klipper_config/moonraker.conf
else
  echo -e "[update_manager webcamd] already exist in moonraker.conf [SKIPPED]"
fi

echo -e "Finished Installation..."
echo -e "Please reboot the PI."
exit 0
