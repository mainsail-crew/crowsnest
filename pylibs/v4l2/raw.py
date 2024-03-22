import ctypes

from pylibs.v4l2 import ioctl_macros

from pylibs.v4l2 import constants

class v4l2_capability(ctypes.Structure):
    _fields_ = [
        ("driver",ctypes.c_char * 16),
        ("card", ctypes.c_char * 32),
        ("bus_info", ctypes.c_char * 32),
        ("version", ctypes.c_uint32),
        ("capabilities", ctypes.c_uint32),
        ("device_caps", ctypes.c_uint32),
        ("reserved", ctypes.c_uint32 * 3)
    ]

class v4l2_control(ctypes.Structure):
    _fields_ = [
        ("id",      ctypes.c_uint32),
        ("value",   ctypes.c_int32)
    ]

class v4l2_ext_control(ctypes.Structure):
    _pack_ = True
    class ValueUnion(ctypes.Union):
        _fields_ = [
            ("value", ctypes.c_int32),
            ("value64", ctypes.c_int64),
            ("string",  ctypes.POINTER(ctypes.c_char)),
            ("p_u8", ctypes.POINTER(ctypes.c_uint8)),
            ("p_u16", ctypes.POINTER(ctypes.c_uint16)),
            ("p_u32", ctypes.POINTER(ctypes.c_uint32)),
            ("p_s32", ctypes.POINTER(ctypes.c_int32)),
            ("p_s64", ctypes.POINTER(ctypes.c_int64)),
            ("ptr", ctypes.POINTER(None))
        ]

    _fields_ = [
        ("id",      ctypes.c_uint32),
        ("size",    ctypes.c_uint32),
        ("reserved2", ctypes.c_uint32 * 1),
        ("union",   ValueUnion)
    ]
    _anonymous_ = ("union",)

class v4l2_ext_controls(ctypes.Structure):
    class UnionControls(ctypes.Union):
        _fields_ = [
            ("ctrl_class", ctypes.c_uint32),
            ("which", ctypes.c_uint32)
        ]

    _fields_ = [
        ("union", UnionControls),
        ("count", ctypes.c_uint32),
        ("error_idx", ctypes.c_uint32),
        ("request_fd", ctypes.c_int32),
        ("reserved", ctypes.c_uint32 * 1),
        ("controls", ctypes.POINTER(v4l2_ext_control) )
    ]
    _anonymous_ = ("union",)

class v4l2_queryctrl(ctypes.Structure):
    _fields_ = [
        ("id",              ctypes.c_uint32),
        ("type",            ctypes.c_uint32),
        ("name",            ctypes.c_char * 8),
        ("minimum",         ctypes.c_int32),
        ("maximum",         ctypes.c_int32),
        ("step",            ctypes.c_int32),
        ("default_value",   ctypes.c_int32),
        ("flags",           ctypes.c_uint32),
        ("reserved",        ctypes.c_uint32 * 2)
    ]

class v4l2_query_ext_ctrl(ctypes.Structure):
    _fields_ = [
        ("id",              ctypes.c_uint32),
        ("type",            ctypes.c_uint32),
        ("name",            ctypes.c_char * 32),
        ("minimum",         ctypes.c_int64),
        ("maximum",         ctypes.c_int64),
        ("step",            ctypes.c_uint64),
        ("default_value",   ctypes.c_int64),
        ("flags",           ctypes.c_uint32),
        ("elem_size",       ctypes.c_uint32),
        ("elems",           ctypes.c_uint32),
        ("nr_of_dims",      ctypes.c_uint32),
        ("dim",             ctypes.c_uint32 * constants.V4L2_CTRL_MAX_DIMS),
        ("reserved",        ctypes.c_uint32 * 32)
    ]

class v4l2_querymenu(ctypes.Structure):
    class UnionNameValue(ctypes.Union):
        _fields_ = [
            ("name", ctypes.c_char * 32),
            ("value", ctypes.c_int64)
        ]
    _pack_ = True
    _fields_ = [
        ("id",          ctypes.c_uint32),
        ("index",       ctypes.c_uint32),
        ("union",       UnionNameValue),
        ("reserved",    ctypes.c_uint32)
    ]
    _anonymous_ = ("union",)


VIDIOC_QUERYCAP                 = ioctl_macros.IOR(ord('V'), 0, v4l2_capability)
VIDIOC_G_CTRL                   = ioctl_macros.IOWR(ord('V'), 27, v4l2_control)
VIDIOC_S_CTRL                   = ioctl_macros.IOWR(ord('V'), 28, v4l2_control)
VIDIOC_QUERYCTRL                = ioctl_macros.IOWR(ord('V'), 36, v4l2_queryctrl)
VIDIOC_QUERYMENU                = ioctl_macros.IOWR(ord('V'), 37, v4l2_querymenu)
VIDIOC_G_EXT_CTRLS              = ioctl_macros.IOWR(ord('V'), 71, v4l2_ext_controls)
VIDIOC_S_EXT_CTRLS              = ioctl_macros.IOWR(ord('V'), 72, v4l2_ext_controls)
VIDIOC_QUERY_EXT_CTRL           = ioctl_macros.IOWR(ord('V'), 103, v4l2_query_ext_ctrl)
