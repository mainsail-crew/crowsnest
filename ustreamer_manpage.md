USTREAMER(1)                General Commands Manual               USTREAMER(1)

NAME\
ustreamer - stream MJPG video from any V4L2 device to the network

SYNOPSIS ustreamer [OPTIONS]

DESCRIPTION\
       µStreamer  (ustreamer) is a lightweight and very quick server to stream
       MJPG video from any V4L2 device to the network.\
       All new  browsers  have native support of this video format, as well as most video players such as mplayer, VLC etc.\
       µStreamer is a part of the Pi-KVM project designed to stream VGA and HDMI screencast hardware data with the highest reso‐
       lution and FPS possible.

USAGE\
       Without arguments, ustreamer will try to open /dev/video0 with  640x480 resolution  and start streaming on http://127.0.0.1:8080.\
       You can override this behavior using parameters --device, --host  and  --port. For example, to stream to the world, run: ustreamer --device=/dev/video1 --host=0.0.0.0 --port=80

       Please note that since µStreamer v2.0 cross-domain requests  were
       disabled  by default for security reasons.
       To enable the old behavior, use the option --allow-origin=\*.

       For example, the recommended way of running µStreamer with
       Auvidea B101 on a Raspberry Pi is:

       ustreamer \
              --format=uyvy \ # Device input format
              --encoder=omx \ # Hardware encoding with OpenMAX
              --workers=3 \ # Maximum workers for OpenMAX
              --persistent \ # Don´t re-initialize device on timeout \
              (for example when HDMI cable was disconnected)
              --dv-timings \ # Use DV-timings
              --drop-same-frames=30 # Save the traffic

       Please note that to use --drop-same-frames for different browsers you need\
       to use some specific URL /stream parameters (see URL / for details).

       You can always view the full list of options with ustreamer --help.
       Some features may not be available on your platform.
       To find out which features are enabled, use ustreamer --features.

OPTIONS

       Capturing options
       -d /dev/path, --device /dev/path
              Path to V4L2 device. Default: /dev/video0.

       -i N, --input N
              Input channel. Default: 0.

       -r WxH, --resolution WxH
              Initial image resolution. Default: 640x480.

       -m fmt, --format fmt
              Image  format.   Available: YUYV, UYVY, RGB565, RGB24, JPEG;
              default: YUYV.

       -a std, --tv-standard std
              Force TV standard.  Available: PAL, NTSC, SECAM;
              Default: disabled.

       -I method, --io-method method
              Set  V4L2 IO method (see kernel documentation). Changing of this
              parameter may increase the performance. Or not.
              Available: MMAP, USERPTR; default: MMAP.

       -f N, --desired-fps N
              Desired FPS. Default: maximum possible.

       -z N, --min-frame-size N
              Drop frames smaller then this limit.
              Useful if the device produces small-sized garbage frames.
              Default: 128 bytes.

       -n, --persistent
              Don't re-initialize device on timeout.
              Default: disabled.

       -t, --dv-timings
              Enable DV timings querying and events  processing  to 
              automatic resolution change.
              Default: disabled.

       -b N, --buffers N
              The number of buffers to receive data from the device. Each buf‐
              fer may processed using an independent thread.
              Default: 2  (the number of CPU cores (but not more than 4) + 1).

       -w N, --workers N
              The  number  of  worker  threads but not more than buffers.  De‐
              fault: 1 (the number of CPU cores (but not more than 4)).

       -q N, --quality N
              Set quality of JPEG encoding from 1 to 100 (best). Default:  80.
              Note: If HW encoding is used (JPEG source format selected), this
              parameter attempts to configure the  camera  or  capture  device
              hardware's  internal encoder. It does not re-encode MJPG to MJPG
              to change the quality level  for  sources  that  already  output
              MJPG.

       -c type, --encoder type
              Use specified encoder. It may affect the number of workers.

              CPU ─ Software MJPG encoding (default).

              OMX  ─  GPU hardware accelerated MJPG encoding with OpenMax (re‐
              quired WITH_OMX feature).

              HW ─ Use pre-encoded MJPG frames directly from camera hardware.

              NOOP ─ Don't compress MJPG stream (do nothing).

       -g WxH,..., --glitched-resolutions WxH,...
              It doesn't do anything. Still here for  compatibility.  Required
              WITH_OMX feature.

       -k path, --blank path
              Path  to JPEG file that will be shown when the device is discon‐
              nected during the streaming. Default: black screen 640x480  with
              'NO SIGNAL'.

       -K sec, --last-as-blank sec
              Show  the  last frame received from the camera after it was dis‐
              connected, but no more than specified time (or endlessly if 0 is
              specified).  If  the device has not yet been online, display 'NO
              SIGNAL' or the image specified by  option  --blank.  Note:  cur‐
              rently  this option has no effect on memory sinks.
              Default: disabled.

       -l, --slowdown
              Slowdown capturing to 1 FPS or  less  when  no  stream  or  sink
              clients  are  connected.  Useful  to reduce CPU consumption.
              Default: disabled.

       --device-timeout sec
              Timeout for device querying. Default: 1.

       --device-error-delay sec
              Delay before trying to connect to the device again after an
              error (timeout for example). Default: 1.

   Image control options
       --image-default
              Reset all image settings below to default. Default: no change.

       --brightness N, auto, default
              Set brightness. Default: no change.

       --contrast N, default
              Set contrast. Default: no change.

       --saturation N, default
              Set saturation. Default: no change.

       --hue N, auto, default
              Set hue. Default: no change.

       --gamma N, default
              Set gamma. Default: no change.

       --sharpness N, default
              Set sharpness. Default: no change.

       --backlight-compensation N, default
              Set backlight compensation. Default: no change.

       --white-balance N, auto, default
              Set white balance. Default: no change.

       --gain N, auto, default
              Set gain. Default: no change.

       --color-effect N, default
              Set color effect. Default: no change.

       --flip-vertical 1, 0, default
              Set vertical flip. Default: no change.

       --flip-horizontal 1, 0, default
              Set horizontal flip. Default: no change.

   HTTP server options
       -s address, --host address
              Listen on Hostname or IP. Default: 127.0.0.1.

       -p N, --port N
              Bind to this TCP port. Default: 8080.

       -U path, --unix path
              Bind to UNIX domain socket. Default: disabled.

       -d, --unix-rm
              Try to remove old unix socket file before binding. default: dis‐
              abled.

       -M mode, --unix-mode mode
              Set UNIX socket file permissions (like 777). Default: disabled.

       --user name
              HTTP basic auth user. Default: disabled.

       --passwd str
              HTTP basic auth passwd. Default: empty.

       --static path
              Path to dir with static files instead  of  embedded  root  index
              page.  Symlinks are not supported for security reasons. Default:
              disabled.

       -e N, --drop-same-frames N
              Don't send identical frames to clients, but no more than  speci‐
              fied  number.  It can significantly reduce the outgoing traffic,
              but will increase the CPU loading. Don't use  this  option  with
              analog  signal  sources  or webcams, it's useless. Default: dis‐
              abled.

       -R WxH, --fake-resolution WxH
              Override image resolution for the /state. Default: disabled.

       --tcp-nodelay
              Set TCP_NODELAY flag to the client /stream socket.  Ignored  for
              --unix.  Default: disabled.

       --allow-origin str
              Set Access-Control-Allow-Origin header. Default: disabled.

       --server-timeout sec
              Timeout for client connections. Default: 10.

JPEG sink options\
With  shared  memory  sink  you  can  write a stream to a file.\
See ustreamer-dump(1) for more info.

       --sink name
              Use the specified shared memory object to sink JPEG frames.  De‐
              fault: disabled.

       --sink-mode mode
              Set JPEG sink permissions (like 777). Default: 660.

       --sink-rm
              Remove shared memory on stop. Default: disabled.

       --sink-client-ttl sec
              Client TTL. Default: 10.

       --sink-timeout sec
              Timeout for lock. Default: 1.

H264 sink options\
Available only if WITH_OMX feature enabled.

       --h264-sink name
              Use  the  specified shared memory object to sink H264 frames en‐
              coded by MMAL. Default: disabled.

       --h264-sink-mode mode
              Set H264 sink permissions (like 777). Default: 660.

       --h264-sink-rm
              Remove shared memory on stop. Default: disabled.

       --h264-sink-client-ttl sec
              Client TTL. Default: 10.

       --h264-sink-timeout sec
              Timeout for lock. Default: 1.

       --h264-bitrate kbps
              H264 bitrate in Kbps. Default: 5000.

       --h264-gop N
              Intarval between keyframes. Default: 30.

   Process options

       --exit-on-parent-death
              Exit the  program  if  the  parent  process  is  dead.
              Required HAS_PDEATHSIG feature. Default: disabled.

       --process-name-prefix str
              Set  process  name prefix which will be displayed in the process
              list like 'str: ustreamer --blah-blah-blah'. Required  WITH_SET‐
              PROCTITLE feature. Default: disabled.

       --notify-parent
              Send  SIGUSR2  to  the parent process when the stream parameters
              are changed. Checking changes is performed for the  online  flag
              and image resolution. Required WITH_SETPROCTITLE feature.

GPIO options\
Available only if WITH_GPIO feature enabled.

       --gpio-device /dev/path
              Path to GPIO character device. Default: /dev/gpiochip0.

       --gpio-consumer-prefix str
              Consumer prefix for GPIO outputs. Default: ustreamer.

       --gpio-prog-running pin
              Set 1 on GPIO pin while µStreamer is running. Default: disabled.

       --gpio-stream-online pin
              Set 1 while streaming. Default: disabled.

       --gpio-has-http-clients pin
              Set 1 while stream has at least one client. Default: disabled.

Logging options

       --log-level N
              Verbosity level of messages from 0 (info) to 3 (debug). Enabling
              debugging messages can slow down the program.  Available levels:
              0 (info), 1 (performance), 2 (verbose), 3 (debug).  Default: 0.

       --perf Enable  performance  messages  (same as --log-level=1). Default:
              disabled.

       --verbose
              Enable verbose messages and lower (same as  --log-level=2).  De‐
              fault: disabled.

       --debug
              Enable  debug  messages  and  lower (same as --log-level=3). De‐
              fault: disabled.

       --force-log-colors
              Force color logging. Default: colored if stderr is a TTY.

       --no-log-colors
              Disable color logging. Default: ditto.

Help options

       -h, --help
              Print this text and exit.

       -v, --version
              Print version and exit.

       --features
              Print list of supported features.

SEE ALSO
       ustreamer-dump(1)

BUGS
       Please  file  any  bugs  and  issues  at   https://github.com/pikvm/ustreamer/issues

AUTHOR
       Maxim Devaev <mdevaev@gmail.com>

HOMEPAGE
       https://pikvm.org/

COPYRIGHT
       GNU General Public License v3.0

November 2020                     version 4.8                     USTREAMER(1)
