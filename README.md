# crowsnest

A webcam daemon for Raspberry Pi OS Lite images like mainsailOS

---

## It inherited his name from Sail ships Crow's nest.

> A crow's nest is a structure in the upper part of the main mast of a ship or a structure that is used as a lookout point.\
> See https://en.wikipedia.org/wiki/Crow's_nest

So, this will be the 'lookout point' for your Printer.

### Install on Raspberry Pi OS

    cd ~
    git clone https://github.com/mainsail-crew/crowsnest.git
    cd crowsnest
    ./install.sh

_This is not tested on other Distributions. If you test that on other Distributions,\
feel free to open a Pull Request to enhance Documentation._

After successful Instalation you should consider to add

    [update_manager webcamd]
    type: git_repo
    path: ~/crowsnest
    origin: https://github.com/mainsail-crew/crowsnest.git

to your moonraker.conf, to get latest and possibly greatest Features.

### To unsinstall 'crowsnest'

    cd crowsnest
    ./uninstall.sh

###

## _NOTE: This project has WIP Status! Changes may occure and possibly break things!_

---

## Simple Configuration

---

All you need to get your Camera up and running is a small block of code in your _webcam.conf_\
In MainsailOS you can do that in mainsail Web Interface.\
Open the 'config' section, there should be the mentioned file.

By default it look like this:

    [webcamd]
    log_path: ~/klipper_logs/webcamd.log
    log_level: quiet

    [cam 1]
    streamer: ustreamer
    port: 8080
    device: /dev/video0
    resolution: 640x480
    max_fps: 15

What that basicly means is:

    log_path: ~/klipper_logs/webcamd.log

Where crowsnest (webcamd) should store its Logfile.

You can choose:

    log_level: quiet

This Option shows a bare minimum Logfile.\
For example:

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

The next option is

    log_level: verbose

This gives you a little more Informations.
It prints out you existing webcam.conf and shows
a detailed info about your configured ( and connected ) cams.\
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
So, truly made for 'Helper for Setup' purposes.

If you want to get the full Details, please use

    log_level: debug

This will show you barely the same as 'verbose' but it prints also your\
configured Start Parameters ( and the defaults ), also it shows\
the Output of your choosen Streamer.\
This option ist more for debugging purposes and has a tendency to overwhelm you if you are not familiar with that.

---

Another Option that affects the 'logging' behavior is

    delete_log: true

If you enable that option, everytime you restart, your existing log file will be deleted.

Now the more interessting part.

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

As the last option:\
This needs some to read further Information.

    custom_flags:

If you enable this in your [cam whatevernameyouset],\
you can add parameters according to your needs.\
Those will be appended to the default/preconfigured parameters.

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

This optional parameter allows you to setup your Cam due v4l2-ctl options.
Unfortunatly this is a complex topic. But I try to explain it, as good I can.

### As an Example

You own a Logitech C920 Camera, these camera needs some tweaks to get a sharp picture.\
A solution was to use a cronjob (timed actions due scripts) that runs a script with some v4l2-ctl commands.

    v4l2-ctl -d /dev/video0 -c focus_auto=0
    v4l2-ctl -d /dev/video0 -c focus_absolute=30

That script gets executed when th Pi boots up.\
Not a comfortable solution.

alexz from the mainsail-crew mentioned it would be a good move when \
this could happen by crowsnest, hassle free for the user.

So, here we go.
Simply add

    v4l2ctl: focus_auto=0,focus_absolute=30

to your camera setup section. \
Restart webcamd via mainsail (or your used UI) and you're good to go.

To determine which options or better said parameters your Webcam provides, \
login to your Pi via ssh and type

    v4l2-ctl -d <yourdevice> -L

_Note: Replace \<yourdevice> with the according string. ex.:_

    v4l2-ctl -d /dev/video0 -L

This will show you a list with available options.

You have to "play around" with those settings if it matches your needs.
simply repeat the commands as mentioned earlier in your ssh connection.

If you have discoverd your setup write that to your webcam.conf as described.

---

## CustomPIOS Module

I have decided to provide an [CustomPiOS Module](https://github.com/guysoft/CustomPiOS) to make it easier to integrate to other Distributions like MainsailOS or similar.
Please see [README.md](./custompios/README.md) in the module folder for\
further Informations.

---

## Credits

I want to give a huge shoutout to _lixxbox_ and _alexz_ from the mainsail-crew.\
Without these guys it simply were not possible to get that done.

They both mentioned improvements and tested a heck out of there machines to get this all functioning well.\
Thank you, mates :) Proud to be a part of.

---

![Mainsail Logo](https://raw.githubusercontent.com/meteyou/mainsail/master/docs/assets/img/logo.png)

**So, with all that said, get your position seaman! Prepare to get wet feets on your Journey.**

## ARRRR yooo rrready to sail?
