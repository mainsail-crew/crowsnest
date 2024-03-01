from . import core, logger

def get_uvc_formats(cam_path: str) -> str:
    command = f'v4l2-ctl -d {cam_path} --list-formats-ext'
    formats = core.execute_shell_command(command)
    # Remove first 3 lines
    formats = '\n'.join(formats.split('\n')[3:])
    return formats

def get_uvc_v4l2ctrls(cam_path: str) -> str:
    command = f'v4l2-ctl -d {cam_path} --list-ctrls-menus'
    v4l2ctrls = core.execute_shell_command(command)
    return v4l2ctrls

def set_v4l2ctrl(section: str, cam_path: str, ctrls: list[str] = None) -> str:
    prefix = "V4L2 Control: "
    if not ctrls:
        logger.log_quiet(f"No parameters set for {section}. Skipped.", prefix)
        return
    logger.log_quiet(f"Device: {section}", prefix)
    logger.log_quiet(f"Options: {', '.join(ctrls)}", prefix)
    avail_ctrls = get_uvc_v4l2ctrls(cam_path)
    for ctrl in ctrls:
        if ctrl.split['='][0].strip().lower() not in avail_ctrls:
            logger.log_quiet(
                f"Parameter '{ctrl}' not available for '{cam_path}'. Skipped.",
                prefix
            )
            continue
        command = f'v4l2-ctl -d {cam_path} -c {ctrl.strip()}'
        v4l2ctrls = core.execute_shell_command(command)
        if not v4l2ctrls:
            logger.log_quiet(f"Failed to set parameter: '{ctrl.strip()}'", prefix)
