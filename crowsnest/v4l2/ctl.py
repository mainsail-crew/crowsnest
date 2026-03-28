#### crowsnest - A webcam Service for multiple Cams and Stream Services.
####
#### Written by Patrick Gehrsitz aka mryel00 <mryel00.github@gmail.com>
#### Copyright 2025 - till today
#### https://github.com/mainsail-crew/crowsnest
####
#### This File is distributed under GPLv3
####

import copy
import os
from typing import Optional

from . import constants, raw, utils

dev_ctls: dict[str, dict[str, dict[str, (raw.v4l2_ext_control, str)]]] = {}


def parse_qc(fd: int, qc: raw.v4l2_query_ext_ctrl) -> dict:
    """
    Parses the query control to an easy to use dictionary
    """
    if qc.type == constants.V4L2_CTRL_TYPE_CTRL_CLASS:
        return {}
    controls = {}
    controls["type"] = utils.v4l2_ctrl_type_to_string(qc.type)
    if qc.type in (constants.V4L2_CTRL_TYPE_INTEGER, constants.V4L2_CTRL_TYPE_MENU):
        controls["min"] = qc.minimum
        controls["max"] = qc.maximum
    if qc.type == constants.V4L2_CTRL_TYPE_INTEGER:
        controls["step"] = qc.step
    if qc.type in (
        constants.V4L2_CTRL_TYPE_INTEGER,
        constants.V4L2_CTRL_TYPE_MENU,
        constants.V4L2_CTRL_TYPE_INTEGER_MENU,
        constants.V4L2_CTRL_TYPE_BOOLEAN,
    ):
        controls["default"] = qc.default_value
    if qc.flags:
        controls["flags"] = utils.ctrlflags2str(qc.flags)
    if qc.type in (
        constants.V4L2_CTRL_TYPE_MENU,
        constants.V4L2_CTRL_TYPE_INTEGER_MENU,
    ):
        controls["menu"] = {}
        for menu in utils.ioctl_iter(
            fd,
            raw.VIDIOC_QUERYMENU,
            raw.v4l2_querymenu(id=qc.id),
            qc.minimum,
            qc.maximum + 1,
            qc.step,
            True,
        ):
            if qc.type == constants.V4L2_CTRL_TYPE_MENU:
                controls["menu"][menu.index] = menu.name.decode()
            else:
                controls["menu"][menu.index] = menu.value
    return controls


def parse_qc_of_path(device_path: str, qc: raw.v4l2_query_ext_ctrl) -> dict:
    """
    Parses the query control to an easy to use dictionary
    """
    fd = None
    try:
        fd = os.open(device_path, os.O_RDWR)
        controls = parse_qc(fd, qc)
        return controls
    except FileNotFoundError:
        return {}
    finally:
        if fd is not None:
            os.close(fd)


def init_device(device_path: str) -> bool:
    """
    Initialize a given device
    """
    fd = None
    try:
        fd = os.open(device_path, os.O_RDWR)
        next_fl = (
            constants.V4L2_CTRL_FLAG_NEXT_CTRL | constants.V4L2_CTRL_FLAG_NEXT_COMPOUND
        )
        qctrl = raw.v4l2_query_ext_ctrl(id=next_fl)
        dev_ctls[device_path] = {}
        for qc in utils.ioctl_iter(fd, raw.VIDIOC_QUERY_EXT_CTRL, qctrl):
            if qc.type == constants.V4L2_CTRL_TYPE_CTRL_CLASS:
                name = qc.name.decode()
            else:
                name = utils.name2var(qc.name.decode())
            dev_ctls[device_path][name] = {
                "qc": copy.deepcopy(qc),
                "values": parse_qc(fd, qc),
            }
            qc.id |= next_fl
        return True
    except FileNotFoundError:
        return False
    finally:
        if fd is not None:
            os.close(fd)


def get_query_controls(device_path: str) -> dict[str, raw.v4l2_ext_control]:
    """
    Initialize a given device
    """
    fd = None
    try:
        fd = os.open(device_path, os.O_RDWR)
        next_fl = (
            constants.V4L2_CTRL_FLAG_NEXT_CTRL | constants.V4L2_CTRL_FLAG_NEXT_COMPOUND
        )
        qctrl = raw.v4l2_query_ext_ctrl(id=next_fl)
        query_controls: dict[str, raw.v4l2_query_ext_ctrl] = {}
        utils.ioctl_safe(fd, raw.VIDIOC_G_EXT_CTRLS, qctrl)
        for qc in utils.ioctl_iter(fd, raw.VIDIOC_QUERY_EXT_CTRL, qctrl):
            if qc.type == constants.V4L2_CTRL_TYPE_CTRL_CLASS:
                name = qc.name.decode()
            else:
                name = utils.name2var(qc.name.decode())
            query_controls[name] = copy.deepcopy(qc)
            qc.id |= next_fl
        return query_controls
    except FileNotFoundError:
        return {}
    finally:
        if fd is not None:
            os.close(fd)


def get_dev_ctl(device_path: str) -> Optional[dict]:
    if device_path not in dev_ctls:
        init_successfull = init_device(device_path)
        if not init_successfull:
            return None
    return dev_ctls[device_path]


def get_dev_ctl_parsed_dict(device_path: str) -> dict:
    if device_path not in dev_ctls and not init_device(device_path):
        return {}
    return utils.ctl_to_parsed_dict(dev_ctls[device_path])


def get_dev_path_by_name(name: str) -> str:
    """
    Get the device path by its name
    """
    prefix = "video"
    for dev in os.listdir("/dev"):
        is_video_device = dev.startswith(prefix) and dev[len(prefix) :].isdigit()
        if not is_video_device:
            continue
        path = f"/dev/{dev}"
        card = get_camera_capabilities(path).get("card", "")
        if name in card:
            return path
    return ""


def get_camera_capabilities(device_path: str) -> dict:
    """
    Get the capabilities of a given device
    """
    fd = None
    try:
        fd = os.open(device_path, os.O_RDWR)
        cap = raw.v4l2_capability()
        utils.ioctl_safe(fd, raw.VIDIOC_QUERYCAP, cap)
        cap_dict = {
            "driver": cap.driver.decode(),
            "card": cap.card.decode(),
            "bus": cap.bus_info.decode(),
            "version": cap.version,
            "capabilities": cap.capabilities,
        }
        return cap_dict
    except FileNotFoundError:
        return {}
    finally:
        if fd is not None:
            os.close(fd)


def get_control_cur_value(device_path: str, control: str) -> int:
    """
    Get the current value of a control of a given device
    """
    qc: raw.v4l2_query_ext_ctrl = dev_ctls[device_path][utils.name2var(control)]["qc"]
    return get_control_cur_value_with_qc(device_path, qc)


def get_control_cur_value_with_qc(
    device_path: str, qc: raw.v4l2_query_ext_ctrl
) -> Optional[int]:
    """
    Get the current value of a control of a given device
    """
    fd = None
    try:
        fd = os.open(device_path, os.O_RDWR)
        ctrl = raw.v4l2_control()
        ctrl.id = qc.id
        utils.ioctl_safe(fd, raw.VIDIOC_G_CTRL, ctrl)
        return ctrl.value
    except FileNotFoundError:
        return None
    finally:
        if fd is not None:
            os.close(fd)


def set_control(device_path: str, control: str, value: int) -> bool:
    """
    Set the value of a control of a given device
    """
    key = utils.name2var(control)
    qc: raw.v4l2_query_ext_ctrl = dev_ctls[device_path][key]["qc"]
    return set_control_with_qc(device_path, qc, value)


def set_control_with_qc(
    device_path: str, qc: raw.v4l2_query_ext_ctrl, value: int
) -> bool:
    fd = None
    try:
        fd = os.open(device_path, os.O_RDWR)
        ctrl = raw.v4l2_control()
        ctrl.id = qc.id
        ctrl.value = value
        if utils.ioctl_safe(fd, raw.VIDIOC_S_CTRL, ctrl) != -1:
            return True
    except FileNotFoundError:
        pass
    finally:
        if fd is not None:
            os.close(fd)
    return False


def get_formats(device_path: str) -> dict:
    """
    Get the available formats of a given device
    """
    fd = None
    try:
        fd = os.open(device_path, os.O_RDWR)
        fmt_desc = raw.v4l2_fmtdesc()
        frmsize = raw.v4l2_frmsizeenum()
        frmival = raw.v4l2_frmivalenum()
        fmt_desc.index = 0
        fmt_desc.type = constants.V4L2_BUF_TYPE_VIDEO_CAPTURE
        formats = {}
        for fmt in utils.ioctl_iter(fd, raw.VIDIOC_ENUM_FMT, fmt_desc):
            format_str = f"[{fmt.index}]: '{utils.fcc2s(fmt.pixelformat)}' ({fmt.description.decode()}"
            if fmt.flags:
                format_str += f", {utils.fmtflags2str(fmt.flags)}"
            format_str += ")"
            formats[format_str] = {}
            frmsize.pixel_format = fmt.pixelformat
            for size in utils.ioctl_iter(fd, raw.VIDIOC_ENUM_FRAMESIZES, frmsize):
                size_str = utils.frmsize_to_str(size)
                formats[format_str][size_str] = []
                frmival.pixel_format = fmt.pixelformat
                frmival.width = frmsize.discrete.width
                frmival.height = frmsize.discrete.height
                for interval in utils.ioctl_iter(
                    fd, raw.VIDIOC_ENUM_FRAMEINTERVALS, frmival
                ):
                    formats[format_str][size_str].append(utils.frmival_to_str(interval))
        return formats
    except FileNotFoundError:
        return {}
    finally:
        if fd is not None:
            os.close(fd)
