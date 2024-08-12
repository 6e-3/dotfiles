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
    echo "usage: $script --user=<default user> --email=<default email>"
}

setup_user_and_email() {
    echo.section 'Configuring Git settings...'

    local github_username
    local github_email
    local username_not_set=false
    local email_not_set=false

    echo -n 'Checking user.name...'
    if github_username=$(git config --global user.name); then
        echo.ok
    else
        echo.notfound
        username_not_set=true
    fi

    echo -n 'Checking user.email...'
    if github_email=$(git config --global user.email); then
        echo.ok
    else
        echo.notfound
        email_not_set=true
    fi

    if "$username_not_set" || "$email_not_set"; then
        if "$username_not_set"; then
            echo.subsection 'Configuring the username...'
            read -p "Please enter username [${USER}]: " github_username
            [[ -z $github_username ]] && github_username="$USER"
            git config -f "$GIT_CONFIG" user.name "$github_username"
            github_username=$(git config --global user.name)
        fi
        if "$email_not_set"; then
            echo.subsection 'Configuring the email...'
            read -p "Please enter email [${EMAIL}]: " github_email
            [[ -z $github_email ]] && github_email="$EMAIL"
            git config -f "$GIT_CONFIG" user.email "$github_email"
            github_email=$(git config --global user.email)
        fi
    fi

    echo.section 'Git configuration is complete!'
    printf "$(echo.sgr bold "$_echo_accent")user.name   $(echo.sgr)${github_username}\n"
    printf "$(echo.sgr bold "$_echo_accent")user.email  $(echo.sgr)${github_email}\n"
}


if [[ $# -eq 0 ]]; then
    usage
    exit 1
fi

# set default user and email
while (( $# > 0 )); do
    case "$1" in
        --user=*)  USER=$(echo "$1" | sed 's/^--user=//') ;;
        --email=*) EMAIL=$(echo "$1" | sed 's/^--email=//') ;;
        *)         abort "$(loginfo) invalid option: $1" ;;
    esac
    shift
done

if ! type git >/dev/null 2>&1; then
    abort "$(loginfo) git command not found"
fi

GIT_COFNIG="${HOME}/.gitconfig"
setup_user_and_email
