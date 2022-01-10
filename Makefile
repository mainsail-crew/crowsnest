#### webcamd - A webcam Service for multiple Cams and Stream Services.
####
#### Written by Stephan Wendel aka KwadFan <me@stephanwe.de>
#### Copyright 2021
#### https://github.com/mainsail-crew/crowsnest
####
#### This File is distributed under GPLv3
####

.PHONY: help install unsinstall build buildclean uninstallgo update

# Setup
USER = $(shell whoami)
BIN_FOLDER = bin

all: help

help:
	@echo "This is intended to install crowsnest."
	@echo ""
	@echo "Some Parts need 'sudo' privileges."
	@echo "You'll be asked for password, if needed."
	@echo ""
	@echo " Usage: make [action]"
	@echo ""
	@echo "  Available actions:"
	@echo ""
	@echo "   install      Installs crowsnest"
	@echo "   uninstall    Uninstalls crowsnest"
	@echo "   update       Updates crowsnest (if needed)"
	@echo "   build        builds binaries"
	@echo "   buildclean   cleans binaries (for recompile)"
	@echo "   uninstallgo  uninstall Go Lang"
	@echo ""

install:
	@bash -c tools/install.sh

uninstall:
	@bash -c tools/uninstall.sh

update:
	@git submodule update --init
	@bash -c tools/update.sh

build:
	$(MAKE) -C $(BIN_FOLDER)

buildclean:
	$(MAKE) -C $(BIN_FOLDER) clean

uninstallgo:
	@bash -c tools/uninstall_go.sh


