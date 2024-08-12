#!/usr/bin/env bash

set -ueo pipefail

source "${HOME:?}/.dotfiles/lib/bash/echo.bash"

script=$(basename "$0")
loginfo() { echo "${script}: ${FUNCNAME[1]}:"; }

abort() {
    echo.error "$*"
    exit 1
}

usage() {
    printf "usage: %s \033[4mgit_hooks_dir\033[m\n" "$script"
}

setup_hooks() {
    echo.section 'Setting up git-hooks...'
    if ! [[ -d ${DOTFILES_PATH}/.git ]]; then
        echo.warn "$(loginfo) the dotfiles are not tracked by git"
        return
    fi
    if ! [[ -d $DST_GIT_HOOKS_PATH ]]; then
        abort "$(loginfo) directory not exists: $DST_GIT_HOOKS_PATH"
    fi

    local dst_hook
    local src_hooks
    local hook_filename
    local result

    src_hooks=$(find "${SRC_GIT_HOOKS_PATH}" -mindepth 1 -type f)

    while read -r src_hook; do
        hook_filename=$(basename "$src_hook")
        dst_hook="${DST_GIT_HOOKS_PATH}/${hook_filename}"
        echo -n "Creating symlink ${hook_filename}..."
        if [[ -e $dst_hook ]]; then
            echo.skip
            echo.warn "$(loginfo) ${dst_hook}: file exists"
            continue
        fi
        if result=$(ln -s "$src_hook" "$dst_hook" 2>&1); then
            echo.ok
        else
            echo.failed
            echo.abort "$(loginfo) $result"
        fi
    done < <(echo "$src_hooks")
}

if [[ $# -ne 1 ]]; then
    usage
    exit 1
fi
if [[ ! -d $1 ]]; then
    abort "$(loginfo) invalid option"
    usage
    exit 1
fi

DOTFILES_PATH="$HOME/.dotfiles"
SRC_GIT_HOOKS_PATH="$1"
DST_GIT_HOOKS_PATH="${DOTFILES_PATH}/.git/hooks"

setup_hooks
