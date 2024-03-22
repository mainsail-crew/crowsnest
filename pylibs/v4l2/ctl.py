"""
Python implementation of v4l2-ctl
"""

import os
import re
import ctypes
import fcntl
import copy
from typing import Generator

from pylibs.v4l2 import raw, constants

qctrls: dict[str, raw.v4l2_ext_control] = {}

def ioctl_safe(fd: int, request: int, arg: ctypes.Structure) -> int:
    try:
        return fcntl.ioctl(fd, request, arg)
    except OSError as e:
        return -1

def ioctl_iter(fd: int, cmd: int, struct: ctypes.Structure,
              start=0, stop=128, step=1, ignore_einval=False
    )-> Generator[ctypes.Structure, None, None]:
    for i in range(start, stop, step):
        struct.index = i
        try:
            fcntl.ioctl(fd, cmd, struct)
            yield struct
        except OSError as e:
            if e.errno == constants.EINVAL:
                if ignore_einval:
                    continue
                break
            elif e.errno == constants.ENOTTY:
                break
            else:
                raise

def v4l2_ctrl_type_to_string(ctrl_type: int) -> str:
    if ctrl_type == constants.V4L2_CTRL_TYPE_INTEGER:
        return "int"
    elif ctrl_type == constants.V4L2_CTRL_TYPE_BOOLEAN:
        return "bool"
    elif ctrl_type == constants.V4L2_CTRL_TYPE_MENU:
        return "menu"
    elif ctrl_type == constants.V4L2_CTRL_TYPE_BUTTON:
        return "button"
    elif ctrl_type == constants.V4L2_CTRL_TYPE_INTEGER64:
        return "int64"
    elif ctrl_type == constants.V4L2_CTRL_TYPE_CTRL_CLASS:
        return "ctrl_class"
    elif ctrl_type == constants.V4L2_CTRL_TYPE_STRING:
        return "str"
    elif ctrl_type == constants.V4L2_CTRL_TYPE_BITMASK:
        return "bitmask"
    elif ctrl_type == constants.V4L2_CTRL_TYPE_INTEGER_MENU:
        return "intmenu"

def name2var(name: str) -> str:
    return re.sub('[^0-9a-zA-Z]+', '_', name).lower()

def ctrlflags2str(flags: int) -> str:
    dict_flags = {
        constants.V4L2_CTRL_FLAG_GRABBED: "grabbed",
		constants.V4L2_CTRL_FLAG_DISABLED: "disabled",
		constants.V4L2_CTRL_FLAG_READ_ONLY: "read-only",
		constants.V4L2_CTRL_FLAG_UPDATE: "update",
		constants.V4L2_CTRL_FLAG_INACTIVE: "inactive",
		constants.V4L2_CTRL_FLAG_SLIDER: "slider",
		constants.V4L2_CTRL_FLAG_WRITE_ONLY: "write-only",
		constants.V4L2_CTRL_FLAG_VOLATILE: "volatile",
		constants.V4L2_CTRL_FLAG_HAS_PAYLOAD: "has-payload",
		constants.V4L2_CTRL_FLAG_EXECUTE_ON_WRITE: "execute-on-write",
		constants.V4L2_CTRL_FLAG_MODIFY_LAYOUT: "modify-layout",
		constants.V4L2_CTRL_FLAG_DYNAMIC_ARRAY: "dynamic-array",
		0: None
	}
    return dict_flags[flags]

def print_qctrl(fd: int, qc: raw.v4l2_query_ext_ctrl) -> int:
    if qc.type == constants.V4L2_CTRL_TYPE_CTRL_CLASS:
        print(f"\n{qc.name.decode()}\n")
        return
    str_first = f"{name2var(qc.name.decode())} ({v4l2_ctrl_type_to_string(qc.type)})"
    str_indent = (35 - len(str_first)) * ' ' + ':'
    message = str_first + str_indent
    if qc.type in (constants.V4L2_CTRL_TYPE_INTEGER, constants.V4L2_CTRL_TYPE_MENU):
        message += f" min={qc.minimum} max={qc.maximum}"
    if qc.type == constants.V4L2_CTRL_TYPE_INTEGER:
        message += f" step={qc.step}"
    if qc.type in (constants.V4L2_CTRL_TYPE_INTEGER, constants.V4L2_CTRL_TYPE_INTEGER_MENU, constants.V4L2_CTRL_TYPE_BOOLEAN):
        message += f" default={qc.default_value}"
    if qc.nr_of_dims == 0:
        ctrl = raw.v4l2_control(id=qc.id)
        if not ioctl_safe(fd, raw.VIDIOC_G_CTRL, ctrl):
            message += " value=" + str(ctrl.value)
    print(message)

    if qc.type in (constants.V4L2_CTRL_TYPE_MENU, constants.V4L2_CTRL_TYPE_INTEGER_MENU):
        for menu in ioctl_iter(fd, raw.VIDIOC_QUERYMENU, raw.v4l2_querymenu(id=qc.id), qc.minimum, qc.maximum + 1, qc.step, True):
            if qc.type == constants.V4L2_CTRL_TYPE_MENU:
                print(f"    {menu.index}: {menu.name.decode()}")
            else:
                print(f"    {menu.index}: {menu.value}")

def parse_qc(fd: int, qc: raw.v4l2_query_ext_ctrl, device_path: str) -> dict:
    """
    Parses the query control to an easy to use dictionary
    """
    if qc.type == constants.V4L2_CTRL_TYPE_CTRL_CLASS:
        return {}
    controls = {}
    controls['type'] = v4l2_ctrl_type_to_string(qc.type)
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
        controls['flags'] = ctrlflags2str(qc.flags)
    if qc.type in (constants.V4L2_CTRL_TYPE_MENU, constants.V4L2_CTRL_TYPE_INTEGER_MENU):
        controls['menu'] = {}
        for menu in ioctl_iter(fd, raw.VIDIOC_QUERYMENU, raw.v4l2_querymenu(id=qc.id), qc.minimum, qc.maximum + 1, qc.step, True):
            if qc.type == constants.V4L2_CTRL_TYPE_MENU:
                controls['menu'][menu.index] = menu.name.decode()
            else:
                controls['menu'][menu.index] = menu.value
    return controls

def init_device(device_path: str) -> None:
    """
    Initialize a given device
    """
    fd = os.open(device_path, os.O_RDWR)
    next_fl = constants.V4L2_CTRL_FLAG_NEXT_CTRL | constants.V4L2_CTRL_FLAG_NEXT_COMPOUND
    qctrl = raw.v4l2_query_ext_ctrl(id=next_fl)
    qctrls[device_path] = {}
    for qc in ioctl_iter(fd, raw.VIDIOC_QUERY_EXT_CTRL, qctrl):
        if qc.type == constants.V4L2_CTRL_TYPE_CTRL_CLASS:
            name = qc.name.decode()
        else:
            name = name2var(qc.name.decode())
        qctrls[device_path][name] = {}
        qctrls[device_path][name]['qc'] = copy.deepcopy(qc)
        qctrls[device_path][name]['values'] = parse_qc(fd, qc, device_path)
        # print_qctrl(fd, qc)
        qc.id |= next_fl
    print(qctrls)
    os.close(fd)


def list_controls(device_path: str) -> None:
    """
    List all controls of a given device
    """
    fd = os.open(device_path, os.O_RDWR)
    for qc in qctrls[device_path].values():
        print_qctrl(fd, qc['qc'])
        # next_fl = constants.V4L2_CTRL_FLAG_NEXT_CTRL | constants.V4L2_CTRL_FLAG_NEXT_COMPOUND
        # qctrl = raw.v4l2_query_ext_ctrl(id=next_fl)
        # for qc in v4l2_iter(fd, raw.VIDIOC_QUERY_EXT_CTRL, qctrl):
        #     qctrls[name2var(qc.name)] = copy.deepcopy(qc)
        #     print_qctrl(fd, qctrl)
        #     qc.id |= next_fl
    os.close(fd)

def get_camera_capabilities(device_path: str) -> dict:
    """
    Get the capabilities of a given device
    """
    fd = os.open(device_path, os.O_RDWR)
    cap = raw.v4l2_capability()
    ioctl_safe(fd, raw.VIDIOC_QUERYCAP, cap)
    cap_dict = {}
    cap_dict['driver'] = cap.driver.decode()
    cap_dict['card'] = cap.card.decode()
    cap_dict['bus'] = cap.bus_info.decode()
    cap_dict['version'] = cap.version
    cap_dict['capabilities'] = cap.capabilities
    os.close(fd)
    return cap_dict

def get_control(device_path: str, control: str) -> int:
    """
    Get the current value of a control of a given device
    """
    fd = os.open(device_path, os.O_RDWR)
    ctrl = raw.v4l2_control()
    qc: raw.v4l2_query_ext_ctrl = qctrls[device_path][name2var(control)]['qc']
    ctrl.id = qc.id
    ioctl_safe(fd, raw.VIDIOC_G_CTRL, ctrl)
    os.close(fd)
    return ctrl.value

def set_control(device_path: str, control: str, value: int) -> None:
    """
    Set the value of a control of a given device
    """
    fd = os.open(device_path, os.O_RDWR)
    ctrl = raw.v4l2_control()
    qc: raw.v4l2_query_ext_ctrl = qctrls[device_path][control]['qc']
    ctrl.id = qc.id
    ctrl.value = value
    ioctl_safe(fd, raw.VIDIOC_S_CTRL, ctrl)
    os.close(fd)
