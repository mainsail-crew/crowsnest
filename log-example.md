# Example Log

## This is an example of a Logfile in 'verbose' mode

    [06/16/22 10:07:45] crowsnest: crowsnest - A webcam Service for multiple Cams and Stream Services.
    [06/16/22 10:07:45] crowsnest: Version: v2.4.0-15-ge42799b
    [06/16/22 10:07:45] crowsnest: Prepare Startup ...
    [06/16/22 10:07:45] crowsnest: INFO: Host information:
    [06/16/22 10:07:45] crowsnest: Host Info: Distribution: Raspbian GNU/Linux 10 (buster)
    [06/16/22 10:07:45] crowsnest: Host Info: Release: MainsailOS release 0.6.1 (buster)
    [06/16/22 10:07:45] crowsnest: Host Info: Kernel: Linux 5.10.63-v7l+ armv7l
    [06/16/22 10:07:45] crowsnest: Host Info: Model: Raspberry Pi 4 Model B Rev 1.2
    [06/16/22 10:07:45] crowsnest: Host Info: Available CPU Cores: 4
    [06/16/22 10:07:45] crowsnest: Host Info: Available Memory: 3748160 kB
    [06/16/22 10:07:45] crowsnest: Host Info: Diskspace (used / total): 2.9G / 7.1G
    [06/16/22 10:07:45] crowsnest: INFO: Checking Dependencys
    [06/16/22 10:07:45] crowsnest: Dependency: 'crudini' found in /usr/bin/crudini.
    [06/16/22 10:07:45] crowsnest: Dependency: 'find' found in /usr/bin/find.
    [06/16/22 10:07:45] crowsnest: Dependency: 'logger' found in /usr/bin/logger.
    [06/16/22 10:07:45] crowsnest: Dependency: 'xargs' found in /usr/bin/xargs.
    [06/16/22 10:07:45] crowsnest: Dependency: 'ffmpeg' found in /usr/bin/ffmpeg.
    [06/16/22 10:07:45] crowsnest: Dependency: 'ustreamer' found in bin/ustreamer/ustreamer.
    [06/16/22 10:07:45] crowsnest: Dependency: 'rtsp-simple-server' found in bin/rtsp-simple-server/rtsp-simple-server.
    [06/16/22 10:07:46] crowsnest: Version Control: ustreamer is up to date. (v4.13)
    [06/16/22 10:07:46] crowsnest: Version Control: rtsp-simple-server is up to date. (v0.19.1)
    [06/16/22 10:07:46] crowsnest: Version Control: ffmpeg is up to date. (4.1.9-0+deb10u1+rpt1)
    [06/16/22 10:07:46] crowsnest: INFO: Print Configfile: '/home/pi/klipper_config/crowsnest.conf'
    [06/16/22 10:07:46] crowsnest: 		[crowsnest]
    [06/16/22 10:07:46] crowsnest: 		log_path: ~/klipper_logs/crowsnest.log
    [06/16/22 10:07:46] crowsnest: 		log_level: verbose
    [06/16/22 10:07:46] crowsnest: 		delete_log: false
    [06/16/22 10:07:46] crowsnest:
    [06/16/22 10:07:46] crowsnest: 		[cam 1]
    [06/16/22 10:07:46] crowsnest: 		mode: mjpg
    [06/16/22 10:07:46] crowsnest: 		port: 8080
    [06/16/22 10:07:46] crowsnest: 		device: /dev/video0
    [06/16/22 10:07:46] crowsnest: 		resolution: 640x480
    [06/16/22 10:07:46] crowsnest: 		max_fps: 15
    [06/16/22 10:07:46] crowsnest: INFO: Detect available Devices
    [06/16/22 10:07:46] crowsnest: INFO: Found 1 total available Device(s)
    [06/16/22 10:07:46] crowsnest: Detected 'Raspicam' Device -> /dev/video0
    [06/16/22 10:07:47] crowsnest: Supported Formats:
    [06/16/22 10:07:47] crowsnest: 		[0]: 'YU12' (Planar YUV 4:2:0)
    [06/16/22 10:07:47] crowsnest: 		Size: Stepwise 32x32 - 2592x1944 with step 2/2
    [06/16/22 10:07:47] crowsnest: 		[1]: 'YUYV' (YUYV 4:2:2)
    [06/16/22 10:07:47] crowsnest: 		Size: Stepwise 32x32 - 2592x1944 with step 2/2
    [06/16/22 10:07:47] crowsnest: 		[2]: 'RGB3' (24-bit RGB 8-8-8)
    [06/16/22 10:07:47] crowsnest: 		Size: Stepwise 32x32 - 2592x1944 with step 2/2
    [06/16/22 10:07:47] crowsnest: 		[3]: 'JPEG' (JFIF JPEG, compressed)
    [06/16/22 10:07:47] crowsnest: 		Size: Stepwise 32x32 - 2592x1944 with step 2/2
    [06/16/22 10:07:47] crowsnest: 		[4]: 'H264' (H.264, compressed)
    [06/16/22 10:07:47] crowsnest: 		Size: Stepwise 32x32 - 2592x1944 with step 2/2
    [06/16/22 10:07:47] crowsnest: 		[5]: 'MJPG' (Motion-JPEG, compressed)
    [06/16/22 10:07:47] crowsnest: 		Size: Stepwise 32x32 - 2592x1944 with step 2/2
    [06/16/22 10:07:47] crowsnest: 		[6]: 'YVYU' (YVYU 4:2:2)
    [06/16/22 10:07:47] crowsnest: 		Size: Stepwise 32x32 - 2592x1944 with step 2/2
    [06/16/22 10:07:47] crowsnest: 		[7]: 'VYUY' (VYUY 4:2:2)
    [06/16/22 10:07:47] crowsnest: 		Size: Stepwise 32x32 - 2592x1944 with step 2/2
    [06/16/22 10:07:47] crowsnest: 		[8]: 'UYVY' (UYVY 4:2:2)
    [06/16/22 10:07:47] crowsnest: 		Size: Stepwise 32x32 - 2592x1944 with step 2/2
    [06/16/22 10:07:47] crowsnest: 		[9]: 'NV12' (Y/CbCr 4:2:0)
    [06/16/22 10:07:47] crowsnest: 		Size: Stepwise 32x32 - 2592x1944 with step 2/2
    [06/16/22 10:07:47] crowsnest: 		[10]: 'BGR3' (24-bit BGR 8-8-8)
    [06/16/22 10:07:47] crowsnest: 		Size: Stepwise 32x32 - 2592x1944 with step 2/2
    [06/16/22 10:07:47] crowsnest: 		[11]: 'YV12' (Planar YVU 4:2:0)
    [06/16/22 10:07:47] crowsnest: 		Size: Stepwise 32x32 - 2592x1944 with step 2/2
    [06/16/22 10:07:47] crowsnest: 		[12]: 'NV21' (Y/CrCb 4:2:0)
    [06/16/22 10:07:47] crowsnest: 		Size: Stepwise 32x32 - 2592x1944 with step 2/2
    [06/16/22 10:07:47] crowsnest: 		[13]: 'RX24' (32-bit XBGR 8-8-8-8)
    [06/16/22 10:07:47] crowsnest: 		Size: Stepwise 32x32 - 2592x1944 with step 2/2
    [06/16/22 10:07:47] crowsnest: Supported Controls:
    [06/16/22 10:07:47] crowsnest:
    [06/16/22 10:07:47] crowsnest: 		User Controls
    [06/16/22 10:07:47] crowsnest:
    [06/16/22 10:07:47] crowsnest: 		brightness 0x00980900 (int) : min=0 max=100 step=1 default=50 value=50 flags=slider
    [06/16/22 10:07:47] crowsnest: 		contrast 0x00980901 (int) : min=-100 max=100 step=1 default=0 value=0 flags=slider
    [06/16/22 10:07:47] crowsnest: 		saturation 0x00980902 (int) : min=-100 max=100 step=1 default=0 value=0 flags=slider
    [06/16/22 10:07:47] crowsnest: 		red_balance 0x0098090e (int) : min=1 max=7999 step=1 default=1000 value=1000 flags=slider
    [06/16/22 10:07:47] crowsnest: 		blue_balance 0x0098090f (int) : min=1 max=7999 step=1 default=1000 value=1000 flags=slider
    [06/16/22 10:07:47] crowsnest: 		horizontal_flip 0x00980914 (bool) : default=0 value=0
    [06/16/22 10:07:47] crowsnest: 		vertical_flip 0x00980915 (bool) : default=0 value=0
    [06/16/22 10:07:47] crowsnest: 		power_line_frequency 0x00980918 (menu) : min=0 max=3 default=1 value=1
    [06/16/22 10:07:47] crowsnest: 		0: Disabled
    [06/16/22 10:07:47] crowsnest: 		1: 50 Hz
    [06/16/22 10:07:47] crowsnest: 		2: 60 Hz
    [06/16/22 10:07:47] crowsnest: 		3: Auto
    [06/16/22 10:07:47] crowsnest: 		sharpness 0x0098091b (int) : min=-100 max=100 step=1 default=0 value=0 flags=slider
    [06/16/22 10:07:47] crowsnest: 		color_effects 0x0098091f (menu) : min=0 max=15 default=0 value=0
    [06/16/22 10:07:47] crowsnest: 		0: None
    [06/16/22 10:07:47] crowsnest: 		1: Black & White
    [06/16/22 10:07:47] crowsnest: 		2: Sepia
    [06/16/22 10:07:47] crowsnest: 		3: Negative
    [06/16/22 10:07:48] crowsnest: 		4: Emboss
    [06/16/22 10:07:48] crowsnest: 		5: Sketch
    [06/16/22 10:07:48] crowsnest: 		6: Sky Blue
    [06/16/22 10:07:48] crowsnest: 		7: Grass Green
    [06/16/22 10:07:48] crowsnest: 		8: Skin Whiten
    [06/16/22 10:07:48] crowsnest: 		9: Vivid
    [06/16/22 10:07:48] crowsnest: 		10: Aqua
    [06/16/22 10:07:48] crowsnest: 		11: Art Freeze
    [06/16/22 10:07:48] crowsnest: 		12: Silhouette
    [06/16/22 10:07:48] crowsnest: 		13: Solarization
    [06/16/22 10:07:48] crowsnest: 		14: Antique
    [06/16/22 10:07:48] crowsnest: 		15: Set Cb/Cr
    [06/16/22 10:07:48] crowsnest: 		rotate 0x00980922 (int) : min=0 max=360 step=90 default=0 value=0 flags=modify-layout
    [06/16/22 10:07:48] crowsnest: 		color_effects_cbcr 0x0098092a (int) : min=0 max=65535 step=1 default=32896 value=32896
    [06/16/22 10:07:48] crowsnest:
    [06/16/22 10:07:48] crowsnest: 		Codec Controls
    [06/16/22 10:07:48] crowsnest:
    [06/16/22 10:07:48] crowsnest: 		video_bitrate_mode 0x009909ce (menu) : min=0 max=1 default=0 value=0 flags=update
    [06/16/22 10:07:48] crowsnest: 		0: Variable Bitrate
    [06/16/22 10:07:48] crowsnest: 		1: Constant Bitrate
    [06/16/22 10:07:48] crowsnest: 		video_bitrate 0x009909cf (int) : min=25000 max=25000000 step=25000 default=10000000 value=10000000
    [06/16/22 10:07:48] crowsnest: 		repeat_sequence_header 0x009909e2 (bool) : default=0 value=0
    [06/16/22 10:07:48] crowsnest: 		h264_i_frame_period 0x00990a66 (int) : min=0 max=2147483647 step=1 default=60 value=60
    [06/16/22 10:07:48] crowsnest: 		h264_level 0x00990a67 (menu) : min=0 max=13 default=11 value=11
    [06/16/22 10:07:48] crowsnest: 		0: 1
    [06/16/22 10:07:48] crowsnest: 		1: 1b
    [06/16/22 10:07:48] crowsnest: 		2: 1.1
    [06/16/22 10:07:48] crowsnest: 		3: 1.2
    [06/16/22 10:07:48] crowsnest: 		4: 1.3
    [06/16/22 10:07:48] crowsnest: 		5: 2
    [06/16/22 10:07:48] crowsnest: 		6: 2.1
    [06/16/22 10:07:48] crowsnest: 		7: 2.2
    [06/16/22 10:07:48] crowsnest: 		8: 3
    [06/16/22 10:07:48] crowsnest: 		9: 3.1
    [06/16/22 10:07:48] crowsnest: 		10: 3.2
    [06/16/22 10:07:48] crowsnest: 		11: 4
    [06/16/22 10:07:48] crowsnest: 		12: 4.1
    [06/16/22 10:07:48] crowsnest: 		13: 4.2
    [06/16/22 10:07:48] crowsnest: 		h264_profile 0x00990a6b (menu) : min=0 max=4 default=4 value=4
    [06/16/22 10:07:48] crowsnest: 		0: Baseline
    [06/16/22 10:07:48] crowsnest: 		1: Constrained Baseline
    [06/16/22 10:07:48] crowsnest: 		2: Main
    [06/16/22 10:07:48] crowsnest: 		4: High
    [06/16/22 10:07:48] crowsnest:
    [06/16/22 10:07:48] crowsnest: 		Camera Controls
    [06/16/22 10:07:48] crowsnest:
    [06/16/22 10:07:48] crowsnest: 		auto_exposure 0x009a0901 (menu) : min=0 max=3 default=0 value=0
    [06/16/22 10:07:48] crowsnest: 		0: Auto Mode
    [06/16/22 10:07:48] crowsnest: 		1: Manual Mode
    [06/16/22 10:07:48] crowsnest: 		exposure_time_absolute 0x009a0902 (int) : min=1 max=10000 step=1 default=1000 value=1000
    [06/16/22 10:07:48] crowsnest: 		exposure_dynamic_framerate 0x009a0903 (bool) : default=0 value=0
    [06/16/22 10:07:48] crowsnest: 		auto_exposure_bias 0x009a0913 (intmenu): min=0 max=24 default=12 value=12
    [06/16/22 10:07:48] crowsnest: 		0: -4000 (0xfffffffffffff060)
    [06/16/22 10:07:49] crowsnest: 		1: -3667 (0xfffffffffffff1ad)
    [06/16/22 10:07:49] crowsnest: 		2: -3333 (0xfffffffffffff2fb)
    [06/16/22 10:07:49] crowsnest: 		3: -3000 (0xfffffffffffff448)
    [06/16/22 10:07:49] crowsnest: 		4: -2667 (0xfffffffffffff595)
    [06/16/22 10:07:49] crowsnest: 		5: -2333 (0xfffffffffffff6e3)
    [06/16/22 10:07:49] crowsnest: 		6: -2000 (0xfffffffffffff830)
    [06/16/22 10:07:49] crowsnest: 		7: -1667 (0xfffffffffffff97d)
    [06/16/22 10:07:49] crowsnest: 		8: -1333 (0xfffffffffffffacb)
    [06/16/22 10:07:49] crowsnest: 		9: -1000 (0xfffffffffffffc18)
    [06/16/22 10:07:49] crowsnest: 		10: -667 (0xfffffffffffffd65)
    [06/16/22 10:07:49] crowsnest: 		11: -333 (0xfffffffffffffeb3)
    [06/16/22 10:07:49] crowsnest: 		12: 0 (0x0)
    [06/16/22 10:07:49] crowsnest: 		13: 333 (0x14d)
    [06/16/22 10:07:49] crowsnest: 		14: 667 (0x29b)
    [06/16/22 10:07:49] crowsnest: 		15: 1000 (0x3e8)
    [06/16/22 10:07:49] crowsnest: 		16: 1333 (0x535)
    [06/16/22 10:07:49] crowsnest: 		17: 1667 (0x683)
    [06/16/22 10:07:49] crowsnest: 		18: 2000 (0x7d0)
    [06/16/22 10:07:49] crowsnest: 		19: 2333 (0x91d)
    [06/16/22 10:07:49] crowsnest: 		20: 2667 (0xa6b)
    [06/16/22 10:07:49] crowsnest: 		21: 3000 (0xbb8)
    [06/16/22 10:07:49] crowsnest: 		22: 3333 (0xd05)
    [06/16/22 10:07:49] crowsnest: 		23: 3667 (0xe53)
    [06/16/22 10:07:49] crowsnest: 		24: 4000 (0xfa0)
    [06/16/22 10:07:49] crowsnest: 		white_balance_auto_preset 0x009a0914 (menu) : min=0 max=10 default=1 value=1
    [06/16/22 10:07:49] crowsnest: 		0: Manual
    [06/16/22 10:07:49] crowsnest: 		1: Auto
    [06/16/22 10:07:49] crowsnest: 		2: Incandescent
    [06/16/22 10:07:49] crowsnest: 		3: Fluorescent
    [06/16/22 10:07:49] crowsnest: 		4: Fluorescent H
    [06/16/22 10:07:49] crowsnest: 		5: Horizon
    [06/16/22 10:07:49] crowsnest: 		6: Daylight
    [06/16/22 10:07:49] crowsnest: 		7: Flash
    [06/16/22 10:07:49] crowsnest: 		8: Cloudy
    [06/16/22 10:07:49] crowsnest: 		9: Shade
    [06/16/22 10:07:49] crowsnest: 		10: Greyworld
    [06/16/22 10:07:49] crowsnest: 		image_stabilization 0x009a0916 (bool) : default=0 value=0
    [06/16/22 10:07:49] crowsnest: 		iso_sensitivity 0x009a0917 (intmenu): min=0 max=4 default=0 value=0
    [06/16/22 10:07:49] crowsnest: 		0: 0 (0x0)
    [06/16/22 10:07:49] crowsnest: 		1: 100000 (0x186a0)
    [06/16/22 10:07:49] crowsnest: 		2: 200000 (0x30d40)
    [06/16/22 10:07:49] crowsnest: 		3: 400000 (0x61a80)
    [06/16/22 10:07:49] crowsnest: 		4: 800000 (0xc3500)
    [06/16/22 10:07:49] crowsnest: 		iso_sensitivity_auto 0x009a0918 (menu) : min=0 max=1 default=1 value=1
    [06/16/22 10:07:49] crowsnest: 		0: Manual
    [06/16/22 10:07:49] crowsnest: 		1: Auto
    [06/16/22 10:07:49] crowsnest: 		exposure_metering_mode 0x009a0919 (menu) : min=0 max=3 default=0 value=0
    [06/16/22 10:07:49] crowsnest: 		0: Average
    [06/16/22 10:07:49] crowsnest: 		1: Center Weighted
    [06/16/22 10:07:49] crowsnest: 		2: Spot
    [06/16/22 10:07:49] crowsnest: 		3: Matrix
    [06/16/22 10:07:49] crowsnest: 		scene_mode 0x009a091a (menu) : min=0 max=13 default=0 value=0
    [06/16/22 10:07:50] crowsnest: 		0: None
    [06/16/22 10:07:50] crowsnest: 		8: Night
    [06/16/22 10:07:50] crowsnest: 		11: Sports
    [06/16/22 10:07:50] crowsnest:
    [06/16/22 10:07:50] crowsnest: 		JPEG Compression Controls
    [06/16/22 10:07:50] crowsnest:
    [06/16/22 10:07:50] crowsnest: 		compression_quality 0x009d0903 (int) : min=1 max=100 step=1 default=30 value=30
    [06/16/22 10:07:50] crowsnest: INFO: No usable CSI Devices found.
    [06/16/22 10:07:50] crowsnest: V4L2 Control:
    [06/16/22 10:07:50] crowsnest: No parameters set for [cam 1]. Skipped.
    [06/16/22 10:07:50] crowsnest: Try to start configured Cams / Services...
    [06/16/22 10:07:50] crowsnest: INFO: Configuration of Section [cam 1] looks good. Continue...
    [06/16/22 10:07:51] crowsnest: Starting ustreamer with Device /dev/video0 ...
    [06/16/22 10:07:52] crowsnest: ... Done!
