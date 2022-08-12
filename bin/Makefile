#### crowsnest - A webcam Service for multiple Cams and Stream Services.
####
#### Written by Stephan Wendel aka KwadFan <me@stephanwe.de>
#### Copyright 2021
#### https://github.com/mainsail-crew/crowsnest
####
#### This File is distributed under GPLv3
####
#### This Makefile is intended to streamline the build of depending binaries.

#### DO NOT MODIFY AT ALL! ####

# Setup
.PHONY: all clean ustreamer rtsp webrtc update

# Paths
USTREAMER_PATH = ustreamer
USTREAMER_REPO = https://github.com/pikvm/ustreamer.git
USTREAMER_OMX_BRANCH = 61ab2a8
ARCH = $(shell uname -m)
RTSP_PATH = rtsp-simple-server
RTSP_ARCH = $(shell uname -m | cut -c '-5' | sed 's/x86_6/amd64/;s/aarch/arm64v8/')
RTSP_VERSION = $(shell cat $(RTSP_PATH)/version)
DL_RTSP = https://github.com/aler9/rtsp-simple-server/releases/download/$(RTSP_VERSION)/
RTSP_ARCHIVE = rtsp-simple-server_$(RTSP_VERSION)_linux_$(RTSP_ARCH).tar.gz

# Custom Flags
MAKEFLAGS += -j$(shell nproc)

# OpenMAX IL Support
OMX_SUPPORT = $(shell [ -d /opt/vc/include ] && echo 1 || echo 0)

# Ustreamer cloned?
USTREAMER_EXIST = $(shell [ -d ustreamer ] > /dev/null && echo 1 || echo 0)

all:
ifeq ($(USTREAMER_EXIST), 0)
	$(info INFO: ustreamer not found, cloning repository.)
	$(shell git clone $(USTREAMER_REPO) ustreamer)
else
	$(info INFO: ustreamer found.)
endif
	$(MAKE) ustreamer-bin
	$(MAKE) rtsp

# Build ustreamer
ustreamer-bin:
ifeq ($(OMX_SUPPORT), 1)
	$(info Compiling ustreamer with OMX Support.)
	$(info Changening to commit '$(USTREAMER_OMX_BRANCH)' )
	$(shell cd ustreamer; git reset -q --hard $(USTREAMER_OMX_BRANCH) \
	; cd ..)
	WITH_OMX=1 $(MAKE) -C $(USTREAMER_PATH)
else
	$(info Compiling ustreamer without OMX Support.)
	$(MAKE) -C $(USTREAMER_PATH)
endif

# Download rtsp-simple-server
rtsp:
	$(info Download $(RTSP_ARCHIVE) from $(DL_RTSP))
	$(shell curl -JLo $(RTSP_PATH)/$(RTSP_ARCHIVE) $(DL_RTSP)$(RTSP_ARCHIVE))
	$(shell tar -C $(RTSP_PATH) -xf $(RTSP_PATH)/$(RTSP_ARCHIVE))
	$(shell rm -f $(RTSP_PATH)/$(RTSP_ARCHIVE))
	$(info Finished.)
# Dirty Hack needed to prevent "make: Nothing to be done for 'rtsp'." message
	@echo > /dev/null

clean:
	$(MAKE) -C $(USTREAMER_PATH) clean
	$(info Clean rtsp-simple-server ...)
	$(shell rm -rf $(RTSP_PATH)/rtsp*)

update:
	$(MAKE) clean
	$(MAKE) all
