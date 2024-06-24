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
    echo '  引数に指定したディレクトリ内のパッケージごとのディレクトリを参照し、'
    echo '  ディレクトリおよびコンフィグファイルのシンボリックリンクを HOME/XDG_CONFIG_HOME に作成します。'
    echo
    echo '  パッケージごとのディレクトリに配置するコンフィグファイルは、'
    echo '  ホームディレクトリからの相対パスと同じディレクトリ構成となるように配置します。'
    echo
    echo '  ディレクトリ構成例:'
    echo '    config_dir'
    echo '    +-- git'
    echo '    |   +-- .gitconfig'
    echo '    |   +-- .gitmessage'
    echo '    +-- vim'
    echo '    |   +-- .vimrc'
    echo '    +-- starship'
    echo '    |   +-- .config'
    echo '    |       +-- starship.toml'
    echo '    +-- ...'
}

create_symlinks() {
    # usage: create_symlinks pkg_dir
    if [[ $# -ne 1 ]]; then
        echo.error "$(loginfo) invalid option: %s" "$@"
        return 1
    fi

    local pkg_dir="$1"
    if [[ ! -d $pkg_dir ]]; then
        echo.error "$(loginfo) package directry not found: $pkg_dir"
        return 1
    fi

    local pkg
    pkg=$(basename "${pkg_dir:?}")

    echo.subsection "$pkg"

    local src_configs
    src_configs=$(find "$pkg_dir" -mindepth 1)

    if [[ -z "$src_configs" ]]; then
        echo.error "$(loginfo) config files not found: $pkg_dir"
        return
    fi

    local config_relpath_fromhome
    local dst
    local link
    local result
    local src
    while read -r src; do
        config_relpath_fromhome="${src#"${pkg_dir}"/}"
        dst="${HOME}/${config_relpath_fromhome:?}"
        echo.debug "$(loginfo) config_relpath_fromhome: $config_relpath_fromhome"
        echo.debug "$(loginfo) src: $src"
        echo.debug "$(loginfo) dst: $dst"

        if [[ -d $src ]]; then
            if [[ -e $dst || -L $dst ]]; then
                continue
            else
                echo -n "Creating directory ${config_relpath_fromhome}..."
                if result=$(mkdir -m 700 "$dst" 2>&1); then
                    echo.ok
                else
                    echo.failed && IS_FAILED=true
                    echo.error "$(loginfo) $result"
                    printf "$(echo.sgr "$_echo_red")Aborting deploy %s configs;(\n" "$pkg"
                    break
                fi
                continue
            fi
        fi

        echo -n "Creating symlink ${config_relpath_fromhome}..."

        if [[ ! -e $dst && ! -L $dst ]]; then
            if result=$(ln -s "$src" "$dst" 2>&1); then
                echo.ok
            else
                echo.failed && IS_FAILED=true
                echo.error "$result"
            fi
        else
            if ! link=$(readlink "$dst"); then
                echo.skip
                echo.warn "$(loginfo) config file already exists: $dst"
            elif [[ $src != "$link" ]]; then
                echo.skip
                echo.warn "$(loginfo) symlink already exists: $dst"
            elif [[ $src = "$link" ]]; then
                echo.exist
            else
                echo.failed && IS_FAILED=true
                echo.error "$(loginfo) update error"
            fi
        fi
    done < <(echo "$src_configs")
}

deploy() {
    local pkg_dirs
    pkg_dirs=$(find "${CONFIG_DIR:?}" -mindepth 1 -maxdepth 1 -type d)

    echo.section 'Deploying the configs...'

    if [[ -z ${pkg_dirs:-} ]]; then
        echo.error "$(loginfo) pkg_dirs not found"
        return 1
    fi

    while read -r pkg_dir; do
        create_symlinks "$pkg_dir"
    done < <(echo "$pkg_dirs")

    if "$IS_FAILED"; then
        echo.attention 'Failed to deploy some dotfiles:/'
        return
    fi
    echo.section 'Dotfiles deployment is completed!'
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
IS_FAILED=false
deploy
