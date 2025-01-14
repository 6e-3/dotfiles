MAKEFILE      := $(firstword $(MAKEFILE_LIST))
DOTFILES_ROOT := $(realpath $(dir $(MAKEFILE)))
CONFIG_DIR    := $(DOTFILES_ROOT)/configs
SCRIPT_DIR    := $(DOTFILES_ROOT)/scripts/make
BREWFILE      := $(DOTFILES_ROOT)/misc/brew/Brewfile

GIT_USER      := 6e-3
GIT_EMAIL     := 173437276+6e-3@users.noreply.github.com
GIT_HOOKS_DIR := $(DOTFILES_ROOT)/misc/git/hooks

.DEFAULT_GOAL := help

.PHONY: help
.PHONY: init install uninstall
.PHONY: link unlink
.PHONY: git-config git-hooks
.PHONY: brew-list brew-install brew-dump

help: ## Show this help message [default]
	@$(SCRIPT_DIR)/help.sh $(MAKEFILE)

init: ## Install dotfiles with initialization
	@DOTFILES_INIT=1 $(DOTFILES_ROOT)/install.sh

install: ## Install dotfiles
	@$(DOTFILES_ROOT)/install.sh

uninstall: ## Uninstall dotfiles
	@$(SCRIPT_DIR)/uninstall.sh

link: ## Create the symbolic links and directories for dotfiles
	@$(SCRIPT_DIR)/link.sh $(CONFIG_DIR)

unlink: ## Remove the symbolic links and directories for dotfiles
	@$(SCRIPT_DIR)/unlink.sh $(CONFIG_DIR)

git-setup: ## Setup git configs
	@$(SCRIPT_DIR)/git_setup.sh --user=$(GIT_USER) --email=$(GIT_EMAIL)

git-hooks: ## Create the symbolic links of GitHooks to dotfiles repository
	@$(SCRIPT_DIR)/git_hooks_setup.sh $(GIT_HOOKS_DIR)

brew-list: ## List all dependencies present in the dotfiles brewfile
	@brew bundle list --all --file $(BREWFILE)

brew-pkg-install: ## Install and upgrade all dependencies from the dotfiles brewfile
	@brew bundle --no-lock --file $(BREWFILE)

brew-dump: ## Write all installed casks/formulae/images/taps into a brewfile in the dotfiles
	@brew bundle dump -f --file $(BREWFILE)
