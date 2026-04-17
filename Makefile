#### crowsnest - A webcam Service for multiple Cams and Stream Services.
####
#### Written by Stephan Wendel aka KwadFan <me@stephanwe.de>
#### Copyright 2021 - 2023
#### Co-authored by Patrick Gehrsitz aka mryel00 <mryel00.github@gmail.com>
#### Copyright 2023 - till today
#### https://github.com/mainsail-crew/crowsnest
####
#### This File is distributed under GPLv3
####

#### Self-Documenting Makefile
#### This is based on https://gellardo.github.io/blog/posts/2021-06-10-self-documenting-makefile/

.DEFAULT_GOAL := help
.PHONY: help

install: ## Install crowsnest (needs leading sudo)
	@bash -c 'tools/install.sh'

uninstall: ## Uninstall crowsnest
	@bash -c 'tools/uninstall.sh'

clean: ## Clean .config
	@if [ -f tools/.config ]; then rm -f tools/.config; fi
	@printf "Removed installer config file ...\n"

config: ## Configure crowsnest installer
	@bash -c 'tools/configure.sh'

help: ## Shows this help
	@printf "crowsnest - A webcam Service for multiple Cams and Stream Services.\n"
	@printf "Usage:\n\n"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

update: ## Update crowsnest (fetches and pulls repository changes)
	@git fetch && git pull
	@sudo bash -c 'tools/libs/manage_apps.sh --reinstall'

upgrade: ## Upgrade crowsnest from v4 to v5
	@sudo -v || (printf "Sudo privileges required for upgrade\n" && exit 1)
	@printf "Backup crowsnest.conf and moonraker.conf, then migrate them ...\n"
	@MIGRATED_PATH="$$(bash -c 'tools/migrate_configs.sh')"; \
	if [ -n "$$MIGRATED_PATH" ]; then \
		printf "%s\n" "$$MIGRATED_PATH" > tools/.migrated_conf_path; \
		printf "Saved migrated config path to tools/.migrated_conf_path\n"; \
	else \
		printf "No migrated config path returned\n"; \
	fi
	@printf "Uninstalling crowsnest v4 ...\n"
	@yes | bash -c 'tools/uninstall.sh'
	@rm -rf bin/ustreamer bin/camera-streamer
	@printf "Updating repository ...\n"
	@git fetch --all
	@git switch v5
	@git pull origin v5
	@printf "Installing crowsnest v5 ...\n"
	@sudo env CROWSNEST_SKIP_REBOOT_PROMPT=1 bash -c 'tools/install.sh'
	@printf "Restoring migrated crowsnest.conf ...\n"
	@if [ -f tools/.migrated_conf_path ]; then \
		MIGRATED_PATH="$$(cat tools/.migrated_conf_path)"; \
		ORIG_PATH="$${MIGRATED_PATH%.v5}"; \
		printf "Restoring %s -> %s\n" "$$MIGRATED_PATH" "$$ORIG_PATH"; \
		mv "$$MIGRATED_PATH" "$$ORIG_PATH"; \
		rm -f tools/.migrated_conf_path; \
	else \
		printf "No migrated config to restore\n"; \
	fi

report: ## Generate report.txt
	@if [ -f ~/report.txt ]; then rm -f ~/report.txt; fi
	@bash -c 'tools/dev-helper.sh -a >> ~/report.txt'
	@sed -ri 's/\x1B\[([0-9]{1,3}(;[0-9]{1,2})?)?[mGK]//g' ~/report.txt

fixworkingdirectory: ## Fix service file WorkingDirectory path
	@sudo sed -i "s~\(WorkingDirectory=\).*~\1$$PWD~" /etc/systemd/system/crowsnest.service
