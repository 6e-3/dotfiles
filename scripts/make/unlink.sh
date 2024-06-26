#!/usr/bin/env bash

set -ueo pipefail

source "${HOME:?}/.dotfiles/lib/bash/echo.bash"
echo.debug() { :; }

script=$(basename "$0")
loginfo() { echo "${script}: ${FUNCNAME[1]}:"; }

usage() {
    echo -e '\033[1mUSAGE\033[m'
    echo -e "  $script \033[4mconfig_dir\033[m"
    echo
    echo -e '\033[1mDESCRIPTION\033[m'
    echo '  引数に指定したコンフィグディレクトリ内のパッケージごとのディレクトリを参照し、'
    echo '  HOME/XDG_CONFIG_HOME 内のシンボリックリンクおよびディレクトリを削除します。'
    echo
    echo '  パッケージごとのディレクトリに配置するコンフィグファイルは、'
    echo '  HOMEディレクトリからの相対パスと同じディレクトリ構成となるように配置します。'
    echo
    echo '  シンボリックリンクを削除したあと、ディレクトリの削除を行います。'
    echo '  ディレクトリが空ではない場合やシンボリックリンクとなっている場合は削除しません。'
    echo '  また XDG_CONFIG_HOME 自体の削除は実行されません。'
    echo
    echo '  ディレクトリ構成例:'
    echo '    config_dir'
    echo '    +-- git'
    echo '    |   +-- .gitconfig'
    echo '    |   +-- .gitmessage'
    echo '    |   +-- ...'
    echo '    +-- vim'
    echo '    |   +-- .vimrc'
    echo '    +-- starship'
    echo '    |   +-- .config'
    echo '    |       +-- starship.toml'
    echo '    +-- ...'
}

remove_configs() {
    # usage: remove_configs pkg_dir

    if [[ $# -ne 1 ]]; then
        echo.error "$(loginfo) invalid option: $@"
        return 1
    fi

    local pkg_dir="$1"
    if [[ ! -d $pkg_dir ]]; then
        echo.error "$(loginfo) package directory not found: $pkg_dir"
        return 1
    fi

    local pkg
    pkg=$(basename "${pkg_dir:?}")

    echo.subsection "$pkg"

    local src_config_files
    local src_config_dirs
    src_config_files=$(find "$pkg_dir" -type f)
    src_config_dirs=$(find "$pkg_dir" -mindepth 1 -type d)

    if [[ -z "$src_config_files" ]]; then
        echo.error "$(loginfo) config files not found: $pkg_dir"
        return
    fi

    # remove file symlinks
    local config_file_relpath_fromhome
    local link
    local result
    local rm_target_file
    while read src_config_file; do
        config_file_relpath_fromhome="${src_config_file#${pkg_dir}/}"
        rm_target_file="${HOME}/${config_file_relpath_fromhome:?}"
        echo.debug "config_file_relpath_fromhome: $config_file_relpath_fromhome"
        echo.debug "rm_target_file: $rm_target_file"

        echo -n "Removing symlink ${config_file_relpath_fromhome}..."

        if [[ ! -e $rm_target_file && ! -L $rm_target_file ]]; then
            echo.ok
            echo.debug "rm: '$rm_target_file' does not exist"
        elif [[ -L $rm_target_file ]]; then
            link=$(readlink "$rm_target_file")
            if [[ $src_config_file = $link ]]; then
                if result=$(rm -v "$rm_target_file" 2>&1); then
                    echo.ok
                else
                    echo.failed
                    echo.error "$(loginfo) $result"
                fi
            else
                echo.skip
                echo.warn "$(loginfo) the rm_target_file is not linked to dotfiles repository: $rm_target_file"
            fi
        else
            echo.skip
            echo.warn "$(loginfo) '$rm_target' is not symbolic link"
        fi
    done < <(echo "$src_config_files")

    # remove directories
    local config_dir_relpath_fromhome
    local rm_target_dir
    local xdg_config_home="${HOME}/.config"

    [[ -z $src_config_dirs ]] && return
    while read src_config_dir; do
        config_dir_relpath_fromhome="${src_config_dir#${pkg_dir}/}"
        rm_target_dir="${HOME}/${config_dir_relpath_fromhome:?}"
        echo.debug "src_config_dir: $src_config_dir"
        echo.debug "config_dir_relpath_fromhome: $config_dir_relpath_fromhome"
        echo.debug "rm_target_dir: $rm_target_dir"

        if [[ $rm_target_dir = $xdg_config_home ]]; then
            echo.debug "'$rm_target_dir' is xdg_config_home, skipping"
            continue
        fi

        echo -n "Removing directory ${config_dir_relpath_fromhome}..."

        if [[ ! -e $rm_target_dir && ! -L $rm_target_dir ]]; then
            echo.ok
            echo.debug "rm: '$rm_target_dir' does not exist"
        elif [[ -L $rm_target_dir ]]; then
            echo.skip
            echo.warn "$(loginfo) the rm_target_dir is symbolic link: $rm_target_dir"
        elif [[ -f $rm_target_dir ]]; then
            echo.skip
            echo.warn "$(loginfo) the rm_target_dir is regular file: $rm_target_dir"
        else
            if [[ -d $rm_target_dir ]]; then
                result=$(find "$rm_target_dir" -mindepth 1)
                if [[ -n $result ]]; then
                    echo.skip
                    echo.warn "$(loginfo) the directory is not empty: $rm_target_dir"
                    continue
                fi
                if result=$(rm -vr "$rm_target_dir" 2>&1); then
                    echo.ok
                else
                    echo.failed
                    echo.error "$(loginfo) $result"
                fi
            else
                echo.skip
                echo.warn "$(loginfo) '$rm_target' is not symbolic link"
            fi
        fi
    done < <(echo "$src_config_dirs")
}

undeploy() {
    local pkg_dirs
    pkg_dirs=$(find "${CONFIG_DIR:?}" -mindepth 1 -maxdepth 1 -type d)

    echo.section 'Undeploying the configs...'

    while read pkg_dir; do
        remove_configs "$pkg_dir"
    done < <(echo "$pkg_dirs")
}

if [[ $# -ne 1  ]]; then
    usage
    exit 1
fi
if [[ ! -d $1 ]]; then
    echo.error "$(loginfo) '$1' not found"
    exit 1
fi

CONFIG_DIR="$1"
undeploy
