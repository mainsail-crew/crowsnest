#### crowsnest - A webcam Service for multiple Cams and Stream Services.
####
#### Written by Stephan Wendel aka KwadFan <me@stephanwe.de>
#### Copyright 2021 - till today
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

build: ## Compile backends / streamer
	bash -c 'bin/build.sh --build'

buildclean: ## Clean backends / streamer (for rebuilding)
	bash -c 'bin/build.sh --clean'

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

report: ## Generate report.txt
	@if [ -f ~/report.txt ]; then rm -f ~/report.txt; fi
	@bash -c 'tools/dev-helper.sh -a >> ~/report.txt'
	@sed -ri 's/\x1B\[([0-9]{1,3}(;[0-9]{1,2})?)?[mGK]//g' ~/report.txt
