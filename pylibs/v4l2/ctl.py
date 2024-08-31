#!/usr/bin/python3

import os
import copy

from . import raw, constants, utils

dev_ctls: dict[str, dict[str, dict[str, (raw.v4l2_ext_control, str)]]] = {}

def parse_qc(fd: int, qc: raw.v4l2_query_ext_ctrl) -> dict:
    """
    Parses the query control to an easy to use dictionary
    """
    if qc.type == constants.V4L2_CTRL_TYPE_CTRL_CLASS:
        return {}
    controls = {}
    controls['type'] = utils.v4l2_ctrl_type_to_string(qc.type)
    if qc.type in (constants.V4L2_CTRL_TYPE_INTEGER, constants.V4L2_CTRL_TYPE_MENU):
        controls['min'] = qc.minimum
        controls['max'] = qc.maximum
    if qc.type == constants.V4L2_CTRL_TYPE_INTEGER:
        controls['step'] = qc.step
    if qc.type in (
        constants.V4L2_CTRL_TYPE_INTEGER,
        constants.V4L2_CTRL_TYPE_MENU,
        constants.V4L2_CTRL_TYPE_INTEGER_MENU,
        constants.V4L2_CTRL_TYPE_BOOLEAN
    ):
        controls['default'] = qc.default_value
    if qc.flags:
        controls['flags'] = utils.ctrlflags2str(qc.flags)
    if qc.type in (constants.V4L2_CTRL_TYPE_MENU, constants.V4L2_CTRL_TYPE_INTEGER_MENU):
        controls['menu'] = {}
        for menu in utils.ioctl_iter(
            fd,
            raw.VIDIOC_QUERYMENU,
            raw.v4l2_querymenu(id=qc.id), qc.minimum, qc.maximum + 1, qc.step, True
        ):
            if qc.type == constants.V4L2_CTRL_TYPE_MENU:
                controls['menu'][menu.index] = menu.name.decode()
            else:
                controls['menu'][menu.index] = menu.value
    return controls

def parse_qc_of_path(device_path: str, qc: raw.v4l2_query_ext_ctrl) -> dict:
    """
    Parses the query control to an easy to use dictionary
    """
    try:
        fd = os.open(device_path, os.O_RDWR)
        controls = parse_qc(fd, qc)
        os.close(fd)
        return controls
    except FileNotFoundError:
        return {}

def init_device(device_path: str) -> bool:
    """
    Initialize a given device
    """
    try:
        fd = os.open(device_path, os.O_RDWR)
        next_fl = constants.V4L2_CTRL_FLAG_NEXT_CTRL | constants.V4L2_CTRL_FLAG_NEXT_COMPOUND
        qctrl = raw.v4l2_query_ext_ctrl(id=next_fl)
        dev_ctls[device_path] = {}
        for qc in utils.ioctl_iter(fd, raw.VIDIOC_QUERY_EXT_CTRL, qctrl):
            if qc.type == constants.V4L2_CTRL_TYPE_CTRL_CLASS:
                name = qc.name.decode()
            else:
                name = utils.name2var(qc.name.decode())
            dev_ctls[device_path][name] = {
                'qc': copy.deepcopy(qc),
                'values': parse_qc(fd, qc)
            }
            qc.id |= next_fl
        os.close(fd)
        return True
    except FileNotFoundError:
        return False

def get_query_controls(device_path: str) -> dict[str, raw.v4l2_ext_control]:
    """
    Initialize a given device
    """
    try:
        fd = os.open(device_path, os.O_RDWR)
        next_fl = constants.V4L2_CTRL_FLAG_NEXT_CTRL | constants.V4L2_CTRL_FLAG_NEXT_COMPOUND
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
        os.close(fd)
        return query_controls
    except FileNotFoundError:
        return {}

def get_dev_ctl(device_path: str) -> dict:
    if device_path not in dev_ctls:
        if not init_device(device_path):
            return None
    return dev_ctls[device_path]

def get_dev_ctl_parsed_dict(device_path: str) -> dict:
    if device_path not in dev_ctls:
        init_device(device_path)
    return utils.ctl_to_parsed_dict(dev_ctls[device_path])

def get_dev_path_by_name(name: str) -> str:
    """
    Get the device path by its name
    """
    prefix = 'video'
    for dev in os.listdir('/dev'):
        if dev.startswith(prefix) and dev[len(prefix):].isdigit():
            path = f'/dev/{dev}'
            if name in get_camera_capabilities(path).get('card'):
                return path
    return ''

def get_camera_capabilities(device_path: str) -> dict:
    """
    Get the capabilities of a given device
    """
    try:
        fd = os.open(device_path, os.O_RDWR)
        cap = raw.v4l2_capability()
        utils.ioctl_safe(fd, raw.VIDIOC_QUERYCAP, cap)
        cap_dict = {
            'driver': cap.driver.decode(),
            'card': cap.card.decode(),
            'bus': cap.bus_info.decode(),
            'version': cap.version,
            'capabilities': cap.capabilities
        }
        os.close(fd)
        return cap_dict
    except FileNotFoundError:
        return {}

def get_control_cur_value(device_path: str, control: str) -> int:
    """
    Get the current value of a control of a given device
    """
    qc: raw.v4l2_query_ext_ctrl = dev_ctls[device_path][utils.name2var(control)]['qc']
    return get_control_cur_value_with_qc(device_path, qc, control)

def get_control_cur_value_with_qc(device_path: str, qc: raw.v4l2_query_ext_ctrl) -> int:
    """
    Get the current value of a control of a given device
    """
    try:
        fd = os.open(device_path, os.O_RDWR)
        ctrl = raw.v4l2_control()
        ctrl.id = qc.id
        utils.ioctl_safe(fd, raw.VIDIOC_G_CTRL, ctrl)
        os.close(fd)
        return ctrl.value
    except FileNotFoundError:
        return None

def set_control(device_path: str, control: str, value: int) -> bool:
    """
    Set the value of a control of a given device
    """
    qc: raw.v4l2_query_ext_ctrl = dev_ctls[device_path][control]['qc']
    return set_control_with_qc(device_path, qc, value)

def set_control_with_qc(device_path: str, qc: raw.v4l2_query_ext_ctrl, value: int) -> bool:
    success = False
    try:
        fd = os.open(device_path, os.O_RDWR)
        ctrl = raw.v4l2_control()
        ctrl.id = qc.id
        ctrl.value = value
        if utils.ioctl_safe(fd, raw.VIDIOC_S_CTRL, ctrl) != -1:
            success = True
        os.close(fd)
        return success
    except FileNotFoundError:
        pass
    return success

def get_formats(device_path: str) -> dict:
    """
    Get the available formats of a given device
    """
    try:
        fd = os.open(device_path, os.O_RDWR)
        fmt = raw.v4l2_fmtdesc()
        frmsize = raw.v4l2_frmsizeenum()
        frmival = raw.v4l2_frmivalenum()
        fmt.index = 0
        fmt.type = constants.V4L2_BUF_TYPE_VIDEO_CAPTURE
        formats = {}
        for fmt in utils.ioctl_iter(fd, raw.VIDIOC_ENUM_FMT, fmt):
            str = f"[{fmt.index}]: '{utils.fcc2s(fmt.pixelformat)}' ({fmt.description.decode()}"
            if fmt.flags:
                str += f", {utils.fmtflags2str(fmt.flags)}"
            str += ')'
            formats[str] = {}
            frmsize.pixel_format = fmt.pixelformat
            for size in utils.ioctl_iter(fd, raw.VIDIOC_ENUM_FRAMESIZES, frmsize):
                size_str = utils.frmsize_to_str(size)
                formats[str][size_str] = []
                frmival.pixel_format = fmt.pixelformat
                frmival.width = frmsize.discrete.width
                frmival.height = frmsize.discrete.height
                for interval in utils.ioctl_iter(fd, raw.VIDIOC_ENUM_FRAMEINTERVALS, frmival):
                    formats[str][size_str].append(utils.frmival_to_str(interval))
        os.close(fd)
        return formats
    except FileNotFoundError:
        return {}
