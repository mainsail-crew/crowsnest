# Todo

## 02 April 2023

### Norelease:

-   Implement auto update function for backends

### Tasks:

-   Test install on Raspberry PI OS Lite 32/64bit
-   Test install on Raspberry using Ubuntu
-   Test install Ubuntu and Debian VM
-   Test custompios module

-   Update documentation
    -   point users to gitbook
    -   update gitbook for camera-streamer usage

#### Code related:

-   refactor `mode` to `streamer` to choose backend
    -   Needs fallback if camera-streamer is not available on non-rpi devices
