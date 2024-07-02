#!/usr/bin/env bash

set -ueo pipefail

source "${HOME:?}/.dotfiles/lib/bash/echo.bash"
echo.debug() { :; }

script=$(basename "$0")
loginfo() {
    if [[ -z ${FUNCNAME[1]:-} ]]; then
        echo -n "${script}:"
    else
        echo -n "${script}: ${FUNCNAME[1]}:"
    fi
}

if [[ ! -t 0 ]]; then
    echo.abort "$(loginfo) 'stdin' is not a TTY"
fi

hello() {
    if [[ -z ${DOTFILES_PATH:-} ]]; then
        echo.abort "$(loginfo) DOTFILES_PATH is not set"
    fi

    local logo='
    _______ _______ _______ _______ _______ _______ _______ _____   _____
   |   |   |    |  |_     _|    |  |     __|_     _|   _   |     |_|     |_
 __|   |   |       |_|   |_|       |__     | |   | |       |       |       |
|__|_______|__|____|_______|__|____|_______| |___| |___|___|_______|_______|'

    local bar_length=76
    local msg=('Hello:)'
               'This is the dotfiles uninstall script.'
               "Date: $(LANG=C date)")
    echo.bar "$bar_length"
    printf "$(echo.sgr bold "$_echo_base")$logo$(echo.sgr)\n" && sleep 0.5
    echo
    for msg in "${msg[@]}"; do
        echo.msg "> $msg"
    done
    echo
    echo.bar "$bar_length"
    echo
}

self-destruct() {
    echo.section 'Self-destructing...'

    local input
    local result
    echo "Delete: $DOTFILES_PATH"
    while true; do
        read -p 'Are you sure you want to delete this? (y/n) ' input
        if [[ $input =~ ^[Yy]|[Yy][Ee][Ss]$ ]]; then
            break
        elif [[ $input =~ ^[Nn]|[Nn][Oo]$ ]]; then
            echo.end_warn 'Aborting dotfiles uninstallation:P'
            exit
        fi
    done

    echo -n "Removing $DOTFILES_PATH..."
    if result=$(rm -rf "${DOTFILES_PATH:?}" 2>&1); then
        echo.ok
    else
        echo.failed
        echo.error "$(loginfo) $result"
        echo.abort 'Uninstallation failed;('
    fi
}

uninstall() {
    echo.title 'Starting dotfiles uninstallation'

    if [[ ! -d $DOTFILES_PATH ]]; then
        echo.abort "$(loginfo) dotfiles directory not found: $DOTFILES_PATH"
    fi

    cd "$DOTFILES_PATH"
    make unlink
    self-destruct
    echo.end_ok 'Dotfiles uninstallation complete!'
}


DOTFILES_PATH="${HOME}/.dotfiles"

hello
echo.attention "$(echo.sgr)Press $(echo.sgr bold)RETURN/ENTER$(echo.sgr) to continue or press any other key to abort."
IFS='' read -sr -n 1 -p 'Ready?' input && echo
if [[ -n ${input:-} ]]; then
    echo.end_warn 'Aborting the uninstallation:P'
    exit
else
    echo
    uninstall
fi
sleep 0.5
printf "$(echo.sgr bold "$_echo_base")GoodBye!👋$(echo.sgr)\n\n"
