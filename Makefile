#### webcamd - A webcam Service for multiple Cams and Stream Services.
####
#### Written by Stephan Wendel aka KwadFan <me@stephanwe.de>
#### Copyright 2021 - 2022
#### https://github.com/mainsail-crew/crowsnest
####
#### This File is distributed under GPLv3
####

.PHONY: build buildclean config help install unsinstall

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
	@echo "   config       Configures Installer"
	@echo "   install      Installs crowsnest (needs sudo)"
	@echo "   uninstall    Uninstalls crowsnest (needs sudo)"
	@echo "   build        builds binaries"
	@echo "   buildclean   cleans binaries (for recompile)"
	@echo "   clean        Removes Installer config"
	@echo ""

install:
	@bash -c 'tools/install.sh'

uninstall:
	@bash -c 'tools/uninstall.sh'

build:
	$(MAKE) -C $(BIN_FOLDER)

buildclean:
	$(MAKE) -C $(BIN_FOLDER) clean

clean:
	@if [ -f tools/.config ]; then rm -f tools/.config; fi
	@echo "Removed installer config file ..."

config:
	@bash -c 'tools/configure.sh'

report:
	@if [ -f ~/report.txt ]; then rm -f ~/report.txt; fi
	@bash -c 'tools/dev-helper.sh -a >> ~/report.txt'
	@sed -ri 's/\x1B\[([0-9]{1,3}(;[0-9]{1,2})?)?[mGK]//g' ~/report.txt


