MAKEFILE      := $(firstword $(MAKEFILE_LIST))
DOTFILES_ROOT := $(realpath $(dir $(MAKEFILE)))
CONFIG_DIR    := $(DOTFILES_ROOT)/configs
SCRIPT_DIR    := $(DOTFILES_ROOT)/scripts/make

GIT_USER      := 6e-3
GIT_EMAIL     := 173437276+6e-3@users.noreply.github.com
GIT_HOOKS_DIR := $(DOTFILES_ROOT)/misc/git/hooks

.DEFAULT_GOAL := help

.PHONY: help
.PHONY: init deploy undeploy
.PHONY: git-config git-hooks

help: ## Show this help message.
	@$(SCRIPT_DIR)/help.sh $(MAKEFILE)

init: ## Initialization.
	@$(SCRIPT_DIR)/init.sh

deploy: ## Create the symbolic links and directories for dotfiles.
	@$(SCRIPT_DIR)/deploy.sh $(CONFIG_DIR)

undeploy: ## Remove the symbolic links and directories for dotfiles.
	@$(SCRIPT_DIR)/undeploy.sh $(CONFIG_DIR)

git-setup: ## Configuration git configs.
	@$(SCRIPT_DIR)/git_setup.sh --user=$(GIT_USER) --email=$(GIT_EMAIL)

git-hooks: ## Create the symbolic links of GitHooks to dotfiles repository.
	@$(SCRIPT_DIR)/git_hooks_setup.sh $(GIT_HOOKS_DIR)
