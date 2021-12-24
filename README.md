[![license](https://img.shields.io/github/license/mainsail-crew/crowsnest?style=flat-square&color=green)](https://github.com/mainsail-crew/crowsnest/blob/master/LICENSE) [![language](https://img.shields.io/github/languages/top/mainsail-crew/crowsnest?style=flat-square&logo=gnubash&logoColor=white)](https://github.com/mainsail-crew/crowsnest/search?l=shell) [![commit-activity](https://img.shields.io/github/commit-activity/m/mainsail-crew/crowsnest?style=flat-square)](https://github.com/mainsail-crew/crowsnest/commits) [![issue-search](https://img.shields.io/github/issues/mainsail-crew/crowsnest?style=flat-square)](https://github.com/mainsail-crew/crowsnest/issues) ![downloads](https://img.shields.io/github/downloads/mainsail-crew/crowsnest/total?style=flat-square) [![discord](https://img.shields.io/discord/758059413700345988?color=%235865F2&label=discord&logo=discord&logoColor=white&style=flat-square)](https://discord.gg/skWTwTD)

# crowsnest

This is a webcam daemon (background process) for Raspberry Pi OS Lite images like mainsailOS

---

## The name "Crowsnest" was derived from a structure in the upper part of the main mast of a sailing ship. "It is a structure that is used as a lookout point.


> See https://en.wikipedia.org/wiki/Crow's_nest

This is intended to be the 'lookout point' for your 3D Printer.

### Installation on Raspberry Pi OS (currently the only tested and supported Operating System)

    cd ~
    git clone https://github.com/mainsail-crew/crowsnest.git
    cd crowsnest
    ./install.sh

_This has not been tested on other Distributions. If you test this on other Distributions,\
it would be helpful to open a Pull Request in order to enhance the Documentation._

In order to keep the installation current and updated add the follollowing lines to moonraker.conf

    [update_manager webcamd]
    type: git_repo
    path: ~/crowsnest
    origin: https://github.com/mainsail-crew/crowsnest.git



### Uninstallation of 'crowsnest' - Perform the following

    cd crowsnest
    ./uninstall.sh

###

## _NOTE:  This project is currently a Work In Progress! By installing this code there is the possibilty that other functions of Mainsail or related components could be affected in an adverse way!_

---

## Basic Configuration

---
After installtion there will be a file created named _webcam.conf_ that will need to have entires added to it.

In order to have your camera(s) functional within Mainsail all that is needed is a small block of code placed within your _webcam.conf_ file.\
The changes to the _webcam.conf_ file can be made within the Mainsail Web Interface
One will need to open and edit the webcam.conf file. To do so click on the Hamburger Menu located in the top left of the Mainsail Web Interface and then click on Machine. The file should be present to allow editing.

The default entries within the file will look as follows:

    [webcamd]
    log_path: ~/klipper_logs/webcamd.log
    log_level: quiet

    [cam 1]
    streamer: ustreamer
    port: 8080
    device: /dev/video0
    resolution: 640x480
    max_fps: 15

The above statements in the file determine where the log file for the webcam(s) is located and what options are selected. By default the path is

    log_path: ~/klipper_logs/webcamd.log

This is where crowsnest (webcamd) stores its Logfile.

Options:

    log_level: quiet

This Option shows a bare minimum and basic Logfile.\
Below is an example of the basic (short) logfile that will be generated 

    [11/02/21 20:47:52] webcamd: webcamd - A webcam Service for multiple Cams and Stream Services.
    [11/02/21 20:47:53] webcamd: Version: v0.1.3-9-g7e278cd
    [11/02/21 20:47:53] webcamd: Prepare Startup ...
    [11/02/21 20:47:53] webcamd: INFO: Checking Dependencys
    [11/02/21 20:47:53] webcamd: Dependency: 'crudini' found in /usr/bin/crudini.
    [11/02/21 20:47:53] webcamd: Dependency: 'mjpg_streamer' found in /usr/local/bin/mjpg_streamer.
    [11/02/21 20:47:53] webcamd: Dependency: 'ustreamer' found in /usr/local/bin/ustreamer.
    [11/02/21 20:47:53] webcamd: Dependency: 'v4l2rtspserver' found in /usr/local/bin/v4l2rtspserver.
    [11/02/21 20:47:54] webcamd: INFO: Detect available Cameras
    [11/02/21 20:47:54] webcamd: INFO: Found 2 available Camera(s)
    [11/02/21 20:47:54] webcamd: /dev/v4l/by-id/usb-USB_Camera_USB_Camera_SN0001-video-index0 -> /dev/video1
    [11/02/21 20:47:54] webcamd: Detected 'Raspicam' Device -> /dev/video0
    [11/02/21 20:47:54] webcamd: Try to start configured Cams / Services...
    [11/02/21 20:47:55] webcamd: INFO: Configuration of Section [cam 1] looks good. Continue...
    [11/02/21 20:47:55] webcamd: Starting mjpeg-streamer with Device /dev/video0 ...
    [11/02/21 20:48:03] webcamd: INFO: Configuration of Section [cam usb_black] looks good. Continue...
    [11/02/21 20:48:04] webcamd: Starting ustreamer with Device /dev/v4l/by-id/usb-USB_Camera_USB_Camera_SN0001-video-index0 ...
    [11/02/21 20:48:11] webcamd: ... Done!



    log_level: verbose

This provies more Information.
This option provides a more detailed and extensive listing of the webcam.conf file. 
The information is more detailed concerning your configured ( and connected ) cams.\
The output will be similar to the following:

    [10/24/21 02:46:00] webcamd: INFO: Detect available Cameras
    [10/24/21 02:46:00] webcamd: INFO: Found 1 available Camera(s)
    [10/24/21 02:46:00] webcamd: Detected 'Raspicam' Device -> /dev/video0
    [10/24/21 02:46:00] webcamd: Supported Formats:
    [10/24/21 02:46:00] webcamd: 		[0]: 'YU12' (Planar YUV 4:2:0)
    [10/24/21 02:46:01] webcamd: 		Size: Stepwise 32x32 - 2592x1944 with step 2/2
    [10/24/21 02:46:01] webcamd: 		[1]: 'YUYV' (YUYV 4:2:2)
    [10/24/21 02:46:01] webcamd: 		Size: Stepwise 32x32 - 2592x1944 with step 2/2
    [10/24/21 02:46:01] webcamd: 		[2]: 'RGB3' (24-bit RGB 8-8-8)
    [10/24/21 02:46:01] webcamd: 		Size: Stepwise 32x32 - 2592x1944 with step 2/2
    [10/24/21 02:46:01] webcamd: 		[3]: 'JPEG' (JFIF JPEG, compressed)
    [10/24/21 02:46:01] webcamd: 		Size: Stepwise 32x32 - 2592x1944 with step 2/2
    [10/24/21 02:46:01] webcamd: 		[4]: 'H264' (H.264, compressed)
    [10/24/21 02:46:01] webcamd: 		Size: Stepwise 32x32 - 2592x1944 with step 2/2
    [10/24/21 02:46:02] webcamd: 		[5]: 'MJPG' (Motion-JPEG, compressed)
    [10/24/21 02:46:02] webcamd: 		Size: Stepwise 32x32 - 2592x1944 with step 2/2
    [10/24/21 02:46:02] webcamd: 		[6]: 'YVYU' (YVYU 4:2:2)
    [10/24/21 02:46:02] webcamd: 		Size: Stepwise 32x32 - 2592x1944 with step 2/2
    [10/24/21 02:46:02] webcamd: 		[7]: 'VYUY' (VYUY 4:2:2)
    [10/24/21 02:46:02] webcamd: 		Size: Stepwise 32x32 - 2592x1944 with step 2/2
    [10/24/21 02:46:02] webcamd: 		[8]: 'UYVY' (UYVY 4:2:2)
    [10/24/21 02:46:02] webcamd: 		Size: Stepwise 32x32 - 2592x1944 with step 2/2
    [10/24/21 02:46:02] webcamd: 		[9]: 'NV12' (Y/CbCr 4:2:0)
    [10/24/21 02:46:03] webcamd: 		Size: Stepwise 32x32 - 2592x1944 with step 2/2
    [10/24/21 02:46:03] webcamd: 		[10]: 'BGR3' (24-bit BGR 8-8-8)
    [10/24/21 02:46:03] webcamd: 		Size: Stepwise 32x32 - 2592x1944 with step 2/2
    [10/24/21 02:46:03] webcamd: 		[11]: 'YV12' (Planar YVU 4:2:0)
    [10/24/21 02:46:03] webcamd: 		Size: Stepwise 32x32 - 2592x1944 with step 2/2
    [10/24/21 02:46:03] webcamd: 		[12]: 'NV21' (Y/CrCb 4:2:0)
    [10/24/21 02:46:03] webcamd: 		Size: Stepwise 32x32 - 2592x1944 with step 2/2
    [10/24/21 02:46:03] webcamd: 		[13]: 'RX24' (32-bit XBGR 8-8-8-8)
    [10/24/21 02:46:03] webcamd: 		Size: Stepwise 32x32 - 2592x1944 with step 2/2

This information proves useful in determing what the Hardware Encoder of your Camera is capable of and gives insight as to what camera resolution the camera is able to display.\
The above output example was provided using an "inexpensive" raspicam (approximate cost $ 7 Dollars) 
The function of the Verbose Log Level is to assist with proper setup of ones cameras and make the process smoother.

For the most comprehensive and full featured details, use the following:

    log_level: debug

The output will be similar to the above mentioned 'verbose' option, but it also prints also includes all of the 
configured Start Parameters (and the defaults), 
and the Output of your choosen Streamer.\
This option is more for debugging purposes and has a tendency to overwhelm one with lots of information. Be prepared if you use this option as interpreting it may be a daunting task.
---

In order to delete ones webcamd.log file after a restart one may use the following option:

    delete_log: true


Additional entries in the file are below and are desctibed below as to thier signifigance.

    [cam 1]
    streamer: ustreamer
    port: 8080
    device: /dev/video0
    resolution: 640x480
    max_fps: 15

> _Note: You can name the cam, how you want!_\
> _ex.: [cam raspicam]_

---

This section should be pretty much self explantory.

    streamer: ustreamer

means your choosen streamservice will be mjpg_streamer.\
You can choose:

- ustreamer - A streamserver from Pi-KVM Project\
  active maintained by [Maxim Devaev](https://github.com/mdevaev)\
  [ustreamer on github](https://github.com/pikvm/ustreamer)

- rtsp - v4l2rtspserver with Multiprotocol Support\
  active maintained by [Michel Promonet](https://github.com/mpromonet) \
  [v4l2rtspserver on github](https://github.com/mpromonet/v4l2rtspserver)
  
  The services mentioned above will be installed when the Crowsnest installation script runs.

More Services will come in the (hopefully, near) future.

---

    port: 8080

The port where the choosen service will listen on\
**_NOTE: If you choose 'rtsp' use Port 8554!_**

**_NOTE: Ports 8080 - 8084 are covered by nginx reverse proxy! \
According to that 8080 will be /webcam, port 8081 will be /webcam1 and so on._**

---

    device: /dev/video0

The Videodevice (Camera) that should be used by the chosen Streamservice.

One may also use an entry similar to the following: 
(Note: to determine what your specific device settings are one may consult the webcamd.log file as they will be listed within the file and allow for an easier copy and paste into the webcam.conf file)

    device: /dev/v4l/by-id/usb-PixArt_Imaging_Inc._USB2.0_Camera-video-index0


---

    resolution: 640x480
    max_fps: 15

The above entries defined the resolution that the camera will attempt to display and the frame rate of the camera :)

Custom Flags Option:\
These flags (if set) will need furhter investigation and undestanding of thier purpose.

    custom_flags:

If you enable this in your [cam whatevernameyouset],\
you can add parameters according to your needs.\
Those will be appended (added) to the default/preconfigured parameters.

To setup Services to your need you have to take a closer look to the documentation of the Projects named above.\
As a pointer in the right direction:

- ustreamer

  - For sake of simplicity I converted ustreamers manpage to
    [ustreamer's manpage](./ustreamer_manpage.md)

- v4l2rtspserver
  - Please visit [v4l2rtspserver Usage](https://github.com/mpromonet/v4l2rtspserver#usage)\

---

### Feature V4L2 Control:

    v4l2ctl:

This optional parameter allows one to setup your Camera using v4l2-ctl options.
This is a complex topic. I will try to explain it to the best of my ability.

### Here is an Example

Using a Logitech C920 Camera, this camera requires some tweaks to get a sharp picture.\
One solution was to use a "cronjob" (an automated script that can be run via Unix or Linux) the script would run with some v4l2-ctl commands.

The script would contain the following entries:

    v4l2-ctl -d /dev/video0 -c focus_auto=0
    v4l2-ctl -d /dev/video0 -c focus_absolute=30

The script would be executed when th Pi boots up.\
This is not an optimal soultion.

alexz from the mainsail-crew suggested that having crowsnest setup these commands would allow these settings to be added with less hassle for the user.

Take a look at [alexz webcam.conf](https://github.com/zellneralex/klipper_config/blob/11f4f8db8ac0e273e25134b571d0a93291f3511e/webcam.conf)

To setup the options add the statement below to your camera setup section.

    v4l2ctl: focus_auto=0,focus_absolute=30


Then restart webcamd (webcam daemon) via mainsail (or your chosen User Interface) and you're good to go.

To determine which options or parameters your current Webcam provides, \
login to your Pi via ssh and type

    v4l2-ctl -d <yourdevice> -L

_Note: Replace \<yourdevice> with the string associated with the device you want to setup. ex.:_

    v4l2-ctl -d /dev/video0 -L

This will show you a list with available options that your camera supports.

There is a certain amount of "trial and error" needed to determine which settings will be needed and usable with your camera.  Find the settings that best  match your needs.
Add the commands using the methood mentioned above to configure. Login to your Raspberry Pi via an ssh connection.

Once you have discovered the settings that will work best for your given camera and situation then make sure to add that to the webcam.conf file as described and save the file.

---

## CustomPIOS Module

[CustomPiOS Module](https://github.com/guysoft/CustomPiOS) is included and designed to make it easier for one to integrate crowsnest into other Linux / Raspberry Pi Distributions like MainsailOS or similar.
Please see [README.md](./custompios/README.md) within the module folder for\
further information.

---

## Credits

I want to give a huge shoutout to _lixxbox_ and _alexz_ from the mainsail-crew.\
Without thier input and assistance it simply would not be possible for crowsnest to be as full featured as it currently is.

Many features and improvements were suggested and they tested a heck out of there machines to get crowsnest to function well.\
Thank you, mates :) Proud to be a part of a group of such talented individuals.

Thanks to [Pedro Lamas](https://github.com/pedrolamas), for providing the ISSUE_TEMPLATES.

---

![Mainsail Logo](https://raw.githubusercontent.com/meteyou/mainsail/master/docs/assets/img/logo.png)

**So, with all that said, get to your positions seaman! Prepare to get your feet wet on your Journey.**

## ARRRR yooo rrready to sail?
