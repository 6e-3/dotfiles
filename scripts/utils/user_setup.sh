#!/usr/bin/env bash

set -ueo pipefail

abort() {
    printf "\033[1;31m%s\033[0m\n" "$*" >&2
    exit 1
}

if [ -z "${BASH_VERSION:-}" ]; then
    abort 'Bash is required to interpret this script.'
fi

usage() {
    local -r script_name=$(basename $0)
    printf "Usage: \033[1m%s\033[m \033[4mUSERNAME\033[m\n" "$script_name"
}

add_user() {
    local -r user_list=$(cat /etc/passwd | awk -F: '{ print $1 }')
    if echo "$user_list" | grep -wq "$username"; then
        echo "User '${username}' already exists."
    else
        useradd -m "$username"
        echo "Added user '${username}'."
    fi
}

set_password() {
    local -r passwd_hash=$(\
        cat /etc/shadow |\
        awk -F: -v username="$username" '{
            if ($1 == username) { print $2 }
        }')
    if [[ $passwd_hash == '!!' ]]; then
        echo 'Password is not set.'
        LANG=C passwd "$username"
    else
        echo 'User password has already been set.'
    fi
}

add_sudoers() {
    local -r group_list=$(cat /etc/group | awk -F: '{print $1}')
    local -r groups=$(groups "$username")
    if echo "$group_list" | grep -wq wheel; then
        if echo "$groups" | grep -wq wheel; then
            echo "User '${username}' is already in the 'wheel' group."
            return
        fi
        usermod -aG wheel "$username"
        echo "User '${username}' joined to 'wheel' group."
    elif echo "$group_list" | grep -wq sudo; then
        if echo "$groups" | grep -wq sudo; then
            echo "User '${username}' is already in the 'sudo' group."
            return
        fi
        usermod -aG sudo "$username"
        echo "User '${username}' joined to 'sudo' group."
    else
        echo 'No group exists that allows sudo.'
        echo 'Skip adding to sudoers.'
    fi
}

setup_ssh() {
    local -r user_dir="/home/${username}"
    local -r ssh_dir="${user_dir}/.ssh"
    local -r ssh_auth_file="${ssh_dir}/authorized_keys"
    if [[ -e $ssh_dir ]]; then
        echo "'${ssh_dir}' already exists."
    else
        mkdir -m 700 "$ssh_dir"
        echo "'${ssh_dir}' created."
    fi
    if [[ -e $ssh_auth_file ]]; then
        echo "'${ssh_auth_file}' already exists."
    else
        touch "$ssh_auth_file"
        echo "'${ssh_auth_file}' created."
        chmod 600 "$ssh_auth_file"
        echo "The permission on '${ssh_auth_file}' were changed to 600."
    fi
    local -r user_owner="${username}:${username}"
    local -r ssh_dir_owner=$(ls -ld "$ssh_dir" | awk '{ print $3":"$4 }')
    local -r ssh_auth_file_owner=$(ls -l "$ssh_auth_file" | awk '{ print $3":"$4 }')
    if [[ ! $ssh_dir_owner == $user_owner ]]; then
        chown "$user_owner" "$ssh_auth_file"
        echo "Changed '${ssh_dir}' owner and group to '${user_owner}'."
    fi
    if [[ ! $ssh_auth_file_owner == $user_owner ]]; then
        chown "$user_owner" "$ssh_dir"
        echo "Changed '${ssh_auth_file}' owner and group to '${user_owner}'."
    fi
}

# main
execution_user=$(whoami)
if [[ $execution_user != root ]]; then
    abort 'Requires root privilege.'
fi
if ! [[ $# -eq 1 ]]; then
    usage
    exit 2
elif ! [[ $1 =~ ^[-_a-zA-Z0-9]+$ ]]; then
    abort 'Invalid username.'
else
    username="$1"
fi

add_user
set_password
add_sudoers
setup_ssh
printf "\033[1;32m%s\033[0m\n" "User setup is complete!" >&2
