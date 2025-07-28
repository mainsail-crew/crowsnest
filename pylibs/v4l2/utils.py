#!/usr/bin/python3

import fcntl
import ctypes
import re
import errno
from typing import Generator

from . import raw, constants


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
            if e.errno == errno.EINVAL:
                if ignore_einval:
                    continue
                break
            elif e.errno in (errno.ENOTTY, errno.ENODATA, errno.EIO):
                break
            else:
                break

def v4l2_ctrl_type_to_string(ctrl_type: int) -> str:
    dict_ctrl_type = {
        constants.V4L2_CTRL_TYPE_INTEGER: "int",
        constants.V4L2_CTRL_TYPE_BOOLEAN: "bool",
        constants.V4L2_CTRL_TYPE_MENU: "menu",
        constants.V4L2_CTRL_TYPE_BUTTON: "button",
        constants.V4L2_CTRL_TYPE_INTEGER64: "int64",
        constants.V4L2_CTRL_TYPE_CTRL_CLASS: "ctrl_class",
        constants.V4L2_CTRL_TYPE_STRING: "str",
        constants.V4L2_CTRL_TYPE_BITMASK: "bitmask",
        constants.V4L2_CTRL_TYPE_INTEGER_MENU: "intmenu"
    }
    return dict_ctrl_type.get(ctrl_type, "unknown") 

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
    return dict_flags.get(flags)

def fmtflags2str(flags: int) -> str:
    dict_flags = {
        constants.V4L2_FMT_FLAG_COMPRESSED: "compressed",
        constants.V4L2_FMT_FLAG_EMULATED: "emulated",
        constants.V4L2_FMT_FLAG_CONTINUOUS_BYTESTREAM: "continuous-bytestream",
        constants.V4L2_FMT_FLAG_DYN_RESOLUTION: "dyn-resolution",
        constants.V4L2_FMT_FLAG_ENC_CAP_FRAME_INTERVAL: "enc-cap-frame-interval",
        constants.V4L2_FMT_FLAG_CSC_COLORSPACE: "csc-colorspace",
        constants.V4L2_FMT_FLAG_CSC_YCBCR_ENC: "csc-ycbcr-enc",
        constants.V4L2_FMT_FLAG_CSC_QUANTIZATION: "csc-quantization",
        constants.V4L2_FMT_FLAG_CSC_XFER_FUNC: "csc-xfer-func"
    }
    return dict_flags.get(flags)

def fcc2s(val: int) -> str:
    s = ''
    s += chr(val & 0x7f)
    s += chr((val >> 8) & 0x7f)
    s += chr((val >> 16) & 0x7f)
    s += chr((val >> 24) & 0x7f)
    return s

def frmtype2s(type) -> str:
    types = [
        "Unknown",
        "Discrete",
        "Continuous",
        "Stepwise"
    ]
    if type >= len(types):
        return "Unknown"
    return types[type]

def fract2sec(fract: raw.v4l2_fract) -> str:
    return "%.3f" % round(fract.numerator / fract.denominator, 3)

def fract2fps(fract: raw.v4l2_fract) -> str:    
    return "%.3f" % round(fract.denominator / fract.numerator, 3)

def frmsize_to_str(frmsize: raw.v4l2_frmsizeenum) -> str:
    string = f"Size: {frmtype2s(frmsize.type)} "
    if frmsize.type == constants.V4L2_FRMSIZE_TYPE_DISCRETE:
        string += "%dx%d" % (frmsize.discrete.width, frmsize.discrete.height)
    elif frmsize.type == constants.V4L2_FRMSIZE_TYPE_CONTINUOUS:
        string += "%dx%d - %dx%d" % (
            frmsize.stepwise.min_width,
            frmsize.stepwise.min_height,
            frmsize.stepwise.max_width,
            frmsize.stepwise.max_height
        )
    elif frmsize.type == constants.V4L2_FRMSIZE_TYPE_STEPWISE:
        string += "%ss - %ss with step %ss (%s-%s fps)" % (
            frmsize.stepwise.min_width,
            frmsize.stepwise.min_height,
            frmsize.stepwise.max_width,
            frmsize.stepwise.max_height,
            frmsize.stepwise.step_width,
            frmsize.stepwise.step_height
        )
    return string

def frmival_to_str(frmival: raw.v4l2_frmivalenum) -> str:
    string = f"Interval: {frmtype2s(frmival.type)} "
    if frmival.type == constants.V4L2_FRMIVAL_TYPE_DISCRETE:
        string += "%ss (%s fps)" % (
            fract2sec(frmival.discrete),
            fract2fps(frmival.discrete)
        )
    elif frmival.type == constants.V4L2_FRMIVAL_TYPE_CONTINUOUS:
        string += "%ss - %ss (%s-%s fps)" % (
            fract2sec(frmival.stepwise.min),
            fract2sec(frmival.stepwise.max),
            fract2fps(frmival.stepwise.max),
            fract2fps(frmival.stepwise.min)
        )
    elif frmival.type == constants.V4L2_FRMIVAL_TYPE_STEPWISE:
        string += "%ss - %ss with step %ss (%s-%s fps)" % (
            fract2sec(frmival.stepwise.min),
            fract2sec(frmival.stepwise.max),
            fract2sec(frmival.stepwise.step),
            fract2fps(frmival.stepwise.max),
            fract2fps(frmival.stepwise.min)
        )
    return string

def ctl_to_parsed_dict(dev_ctl: raw.v4l2_ext_control) -> dict:
    values = {}
    cur_sec = ''
    for control, cur_ctl in dev_ctl.items():
        if not cur_ctl['values']:
            cur_sec = control
            values[cur_sec] = {}
            continue
        values[cur_sec][control] = cur_ctl['values']
    return values
