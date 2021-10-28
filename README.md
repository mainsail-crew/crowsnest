# crowsnest

A webcam daemon for Raspi Lite images like mainsailOS

---

It inherited his name from Sail ships Crow's nest.
---
> A crow's nest is a structure in the upper part of the main mast of a ship or a structure that is used as a lookout point.\
See https://en.wikipedia.org/wiki/Crow's_nest

So, this will be the 'lookout point' for your Printer.

### Install on MainsailOS 0.5.0 as update
    cd ~
    git clone https://github.com/mainsail-crew/crowsnest.git
    cd crowsnest
    ./installer_ms050.sh

An installer for other Distribution than MainsailOS will come.
Give me some time to prepare!

_NOTE: This project has WIP Status! Changes may occure and possibly break things!_
--- 

---

## Simple Configuration
---

All you need to get your Camera up and running is a small block of code in your _webcam.conf_\
In MainsailOS you can do that in mainsail Web Interface.\
Open the 'config' section, there should be the mentioned file.

By default it look like this:

    [webcamd]
    log_path: ~/klipper_logs/webcamd.log
    debug_log: false                        

    [cam 1]
    streamer: mjpg                          
    port: 8080                              
    device: /dev/video0                     
    resolution: 640x480                     
    max_fps: 15

What that basicly means is:

    log_path: ~/klipper_logs/webcamd.log

Where crowsnest (webcamd) should store its Logfile.

    debug_log: false

You can set this to true or false.\
In case of true you get an more verbose output in the log file.
Useful to DEBUG your setup.

Now the more interessting part.

    [cam 1]
    streamer: mjpg                          
    port: 8080                              
    device: /dev/video0                     
    resolution: 640x480                     
    max_fps: 15

> _Note: You can name the cam, how you want!_\
_ex.: [cam raspicam]_

---

This section should be pretty much self explantory.

    streamer: mjpg

means your choosen streamservice will be mjpg_streamer.\
You can choose:
- mjpg - well known [Jacksonliam's mjpg-streamer-experimental](https://github.com/jacksonliam/mjpg-streamer)

- ustreamer - A streamserver from Pi-KVM Project\
active maintained by [Maxim Devaev](https://github.com/mdevaev)\
[ustreamer on github](https://github.com/pikvm/ustreamer)

- rtsp - v4l2rtspserver with Multiprotocol Support\
active maintained by [Michel Promonet](https://github.com/mpromonet) \
[v4l2rtspserver on github](https://github.com/mpromonet/v4l2rtspserver)

More Services will come in the (hopefully, near) future.

---

    port: 8080

The port where the choosen service will listen on\
**_NOTE: If you choose 'rtsp' use Port 8554!_**

**_NOTE: Ports 8080 - 8084 are covered by nginx reverse proxy! \
According to that 8080 will be /webcam, port 8081 will be /webcam1 and so on._**

---

    device: /dev/video0

The Videodevice (Camera) what should be used by choosen Streamservice.

    device: /dev/v4l/by-id/usb-PixArt_Imaging_Inc._USB2.0_Camera-video-index0

is also valid. Your devices are listed in your log-file on every run.\
So, you can easily copy it from there.

---

    resolution: 640x480                     
    max_fps: 15

This last 2 should be pretty obvious :)

---

There are two more existing parameters,

    log_method: debug

**This parameter _has_ to reside under [webcamd] section!**

This forces webcamd to spit out more camera informations.\
Like that:

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

This is useful to determine what the Hardware Encoder of your Camera is capable of.\
In this case a "cheap" raspicam for about 7€ was used.\
But it has a downside, everytime you restart webcamd, it will delete the Logfile!
So, truly made for Debugging purposes.

---

As the last option:\
This needs some to read further Information.

    custom_flags:

If you enable this in your [cam whatevernameyouset],\
you can add parameters according to your needs.\
Those will be appended to the default/preconfigured parameters.

_In case of mjpg_streamer you could (at this Point) only add parameters\
to the "input_" section!_ 

To setup Services to your need you have to take a closer look to the documentation of the Projects named above.\
As a pointer in the right direction:


- mjpg
    - This one is a bit more complex due the fact it depends on your cam type.
    - For 'Raspicam' see [Plugin: input_raspicam](https://github.com/jacksonliam/mjpg-streamer/blob/master/mjpg-streamer-experimental/plugins/input_raspicam/README.md)
    - For USB Type Cams see [Plugin: input_uvc](https://github.com/jacksonliam/mjpg-streamer/blob/master/mjpg-streamer-experimental/plugins/input_uvc/README.md)

- ustreamer
    - For sake of simplicity I converted ustreamers manpage to
    [ustreamer's manpage](./ustreamer_manpage.md)

- v4l2rtspserver
    - Please visit [v4l2rtspserver Usage](https://github.com/mpromonet/v4l2rtspserver#usage)
    

---
## CustomPIOS Module

I have decided to provide an [CustomPiOS Module](https://github.com/guysoft/CustomPiOS) to make it easier to integrate to other Distributions like MainsailOS or similar.
Please see [README.md](./custompios/README.md) in the module folder for\
further Informations.


---

![Mainsail Logo](https://raw.githubusercontent.com/meteyou/mainsail/master/docs/assets/img/logo.png)

**So, with all that said, get your position seaman! Prepare to get wet feets on your Journey.**

## ARRRR yooo rrready to sail?
