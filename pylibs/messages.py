import time

TITLE="\e[31mcrowsnest\e[0m - A webcam daemon for multiple cams and stream services."

### All message intendations are intended as they are

missing_args_msg = """
    echo -e "crowsnest: Missing Arguments!"
    echo -e "\n\tTry: crowsnest -h\n"
"""

wrong_args_msg = """
    echo -e "crowsnest: Wrong Arguments!"
    echo -e "\n\tTry: crowsnest -h\n"
"""

help_msg = """
    echo -e "crowsnest - webcam deamon\nUsage:"
    echo -e "\t crowsnest [Options]"
    echo -e "\n\t\t-h Prints this help."
    echo -e "\n\t\t-v Prints Version of crowsnest."
    echo -e "\n\t\t-c </path/to/configfile>\n\t\t\tPath to your webcam.conf\n"
}"""

deprecated_msg_1 = """{
    log_msg "Parameter 'streamer' is deprecated!"
    log_msg "Please use mode: [ mjpg | multi ]"
    log_msg "ERROR: Please update your crowsnest.conf! Stopped."
}
"""

unknown_mode_msg = """{
    log_msg "WARN: Unknown Mode configured!"
    log_msg "WARN: Using 'mode: mjpg' as fallback!"
}"""

## v4l2_control lib
detected_broken_dev_msg = """{
    log_msg "WARN: Detected 'brokenfocus' device."
    log_msg "INFO: Trying to set to configured Value."
}"""

# call debug_focus_val_msg <value>
# ex.: debug_focus_val_msg focus_absolute=30
debug_focus_val_msg = """{
    log_msg "DEBUG: Value is now: ${1}"
}"""

## blockyfix
blockyfix_msg_1 = """{
    log_msg "INFO: Blockyfix: Setting video_bitrate_mode to constant."
}"""
