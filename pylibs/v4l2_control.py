from . import logger, utils

from .v4l2 import ctl as v4l2_ctl

def get_uvc_formats(cam_path: str) -> str:
    command = f'v4l2-ctl -d {cam_path} --list-formats-ext'
    formats = utils.execute_shell_command(command)
    # Remove first 3 lines
    formats = '\n'.join(formats.split('\n')[3:])
    return formats

def get_uvc_v4l2ctrls(cam_path: str) -> str:
    command = f'v4l2-ctl -d {cam_path} --list-ctrls-menus'
    v4l2ctrls = utils.execute_shell_command(command)
    return v4l2ctrls

def set_v4l2_ctrl(cam_path: str, ctrl: str, prefix='') -> str:
    try:
        c = ctrl.split('=')[0].strip().lower()
        v = int(ctrl.split('=')[1].strip())
        if not v4l2_ctl.set_control(cam_path, c, v):
            raise ValueError
    except (ValueError, IndexError):
        logger.log_quiet(f"Failed to set parameter: '{ctrl.strip()}'", prefix)

def set_v4l2ctrls(section: str, cam_path: str, ctrls: list[str] = None) -> str:
    prefix = "V4L2 Control: "
    if not ctrls:
        logger.log_quiet(f"No parameters set for {section}. Skipped.", prefix)
        return
    logger.log_quiet(f"Device: {section}", prefix)
    logger.log_quiet(f"Options: {', '.join(ctrls)}", prefix)
    avail_ctrls = utils.get_v4l2_ctl_str(cam_path)
    for ctrl in ctrls:
        c = ctrl.split('=')[0].strip().lower()
        if c not in avail_ctrls:
            logger.log_quiet(
                f"Parameter '{ctrl.strip()}' not available for '{cam_path}'. Skipped.",
                prefix
            )
            continue
        set_v4l2_ctrl(cam_path, ctrl, prefix)
    logger.log_multiline(utils.get_v4l2_ctl_str(cam_path), logger.log_debug)

def get_cur_v4l2_value(cam_path: str, ctrl: str) -> str:
    return v4l2_ctl.get_control_cur_value(cam_path, ctrl)

def brokenfocus(cam_path: str, focus_absolute_conf: str) -> str:
    cur_val = get_cur_v4l2_value(cam_path, 'focus_absolute')
    if cur_val and cur_val != focus_absolute_conf:
        logger.log_warning(f"Detected 'brokenfocus' device.")
        logger.log_info(f"Try to set to configured Value.")
        set_v4l2_ctrl(cam_path, f'focus_absolute={focus_absolute_conf}')
        logger.log_debug(f"Value is now: {get_cur_v4l2_value(cam_path, 'focus_absolute')}")

# This function is to set bitrate on raspicams.
# If raspicams set to variable bitrate, they tend to show
# a "block-like" view after reboots
# To prevent that blockyfix should apply constant bitrate befor start of ustreamer
# See https://github.com/mainsail-crew/crowsnest/issues/33
def blockyfix(device: str):
    set_v4l2_ctrl(device, 'video_bitrate_mode=1')
    set_v4l2_ctrl(device, 'video_bitrate=15000000')
