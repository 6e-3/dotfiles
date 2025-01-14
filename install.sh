#!/usr/bin/env bash

set -ueo pipefail

abort() {
    printf "\033[1;31m%s\033[0m\n" "$*" >&2
    exit 1
}

if [ -z "${BASH_VERSION:-}" ]; then
    abort "Bash is required."
fi

script=$(basename "$0")
loginfo() {
    if [[ -z ${FUNCNAME[1]:-} ]]; then
        echo -n "${script}:"
    else
        echo -n "${script}: ${FUNCNAME[1]}:"
    fi
}

user=$(whoami)
if [[ $user == root ]]; then
    abort "$(loginfo) don't run this as root"
fi

if [[ ! -t 0 ]]; then
    abort "$(loginfo) 'stdin' is not a TTY"
fi

cmd_exists_check() {
    local cmd
    local quiet=false
    while (( $# > 0 )); do
        case "$1" in
            -q) quiet=true;;
            *)
                cmd="$*"
                break;;
        esac
        shift
    done
    if "$quiet"; then
        if type "$cmd" >/dev/null 2>&1; then
            return
        else
            return 1
        fi
    else
        printf "Checking the $(echo.sgr bold "$_echo_accent")%s$(echo.sgr) command..." "$cmd"
        if type "$cmd" >/dev/null 2>&1; then
            echo.exist
            return
        else
            echo.notfound
            return 1
        fi
    fi
}

platform_detection() {
    echo.title 'Detecting platform'
    local os
    os=$(uname -o)
    case "$os" in
        Darwin)    PLATFORM='mac' ;;
        GNU/Linux) PLATFORM='linux' ;;
        *)         echo.abort "$(loginfo) unknown os: $os" ;;
    esac
    printf "Platform detected: $(echo.sgr bold "$_echo_accent")$PLATFORM$(echo.sgr)\n"
    echo
}

check_make() {
    if "$MAKE_CHECKED"; then
        return
    else
        MAKE_CHECKED=true
    fi
    local result
    if ! cmd_exists_check 'make'; then
        echo.abort 'make command required'
    fi
    echo -n 'Testing the make utility execution...'
    if result=$(make 2>&1); then
        echo.ok
    else
        echo.failed
        echo.error "$(loginfo) $result"
        echo.abort 'make command test failed'
    fi
}

dotfiles_hello() {
    # variables check
    if [[ -z ${GITHUB_USERNAME:-} ]]; then
        abort "$(loginfo) 'GITHUB_USERNAME' is not set"
    fi
    if [[ -z ${DOTFILES_BRANCH:-} ]]; then
        abort "$(loginfo) 'DOTFILES_BRANCH' is not set"
    fi
    if [[ -z ${DOTFILES_PATH:-} ]]; then
        abort "$(loginfo) 'DOTFILES_PATH' is not set"
    fi
    if [[ -z ${DOTFILES_SSH_URL:-} ]]; then
        abort "$(loginfo) 'DOTFILES_SSH_URL' is not set"
    fi
    if [[ -z ${DOTFILES_TARBALL_URL:-} ]]; then
        abort "$(loginfo) 'DOTFILES_TARBALL_URL' is not set"
    fi
    if [[ -z ${LIB_ECHO_PATH:-} ]]; then
        abort "$(loginfo) 'LIB_ECHO_PATH' is not set"
    fi
    if [[ -z ${LIB_ECHO_URL:-} ]]; then
        abort "$(loginfo) 'LIB_ECHO_URL' is not set"
    fi

    local msg=('Hello:)'
               'This is the dotfiles installation script.'
               "Date: $(LANG=C date)"
               "Download Branch: $DOTFILES_BRANCH")
    local errors=()
    local logo='
    _____  _______ _______ _______ _______ _____   _______ _______ 
   |     \|       |_     _|    ___|_     _|     |_|    ___|     __|
 __|  --  |   -   | |   | |    ___|_|   |_|       |    ___|__     |
|__|_____/|_______| |___| |___|   |_______|_______|_______|_______|'

    if [[ -f $LIB_ECHO_PATH ]]; then
        source "$LIB_ECHO_PATH"
        msg+=("Library: $LIB_ECHO_PATH")
    else
        local lib_downloader
        if type curl >/dev/null 2>&1; then
            lib_downloader='curl'
        elif type wget >/dev/null 2>&1; then
            lib_downloader='wget'
        else
            lib_downloader='library downloader not found'
        fi
        if case "$lib_downloader" in
               curl)
                  msg+=("Library: curl: $LIB_ECHO_URL")
                  lib_echo=$(curl -fsSL "$LIB_ECHO_URL" 2>&1)
                  ;;
               wget)
                  msg+=("Library: wget: $LIB_ECHO_URL")
                  lib_echo=$(wget -qO - "$LIB_ECHO_URL" || echo "wget: error")
                  ;;
               *)
                  lib_echo='downloader not found'
                  false
                  ;;
           esac
        then
            eval "$lib_echo"
        else
            errors+=("$(loginfo) ${lib_echo}: ${LIB_ECHO_URL}")
        fi
    fi

    if [[ -n ${errors:=} ]]; then
        printf "\033[1;31m%s\033[m\n\n" "$logo" && sleep 0.5
        for msg in "${msg[@]}"; do
            printf "\033[1;31m> %s\033[m\n" "$msg"
            sleep 0.2
        done
        echo
        for msg in "${errors[@]}"; do
            printf "\033[31mERROR\033[m: %s\n" "$msg"
        done
        exit 1
    else
        local bar_length=67
        echo.bar "$bar_length"
        printf "$(echo.sgr bold "$_echo_base")%s$(echo.sgr)\n\n" "$logo" && sleep 0.5
        for msg in "${msg[@]}"; do
            echo.msg "> $msg"
        done
        echo
        echo.bar "$bar_length"
        echo
    fi
}

dotfiles_download() {
    check_downloader() {
        echo.section 'Checking downloader...'
        if [[ -z ${DOTFILES_DOWNLOADER:-} ]]; then
            if cmd_exists_check 'git'; then
                DOTFILES_DOWNLOADER='git'
            elif cmd_exists_check 'curl'; then
                DOTFILES_DOWNLOADER='curl'
            elif cmd_exists_check 'wget'; then
                DOTFILES_DOWNLOADER='wget'
            else
                echo.error "$(loginfo) downloader not found: git, curl, wget"
                return 1
            fi
            printf "Automatically detected downloader: $(echo.sgr bold "$_echo_accent")%s$(echo.sgr)\n" "$DOTFILES_DOWNLOADER"
        else
            printf "Specified downloader: $(echo.sgr bold "$_echo_accent")%s$(echo.sgr)\n" "$DOTFILES_DOWNLOADER"
        fi
    }
    termination_with_check_ssh() {
        local -r ssh_dir="${HOME}/.ssh"
        echo.title 'Checking SSH settings'
        if [[ -e $ssh_dir ]]; then
            echo "'$ssh_dir' already exists."
            if [[ -z $(find "$ssh_dir" -maxdepth 0 -perm 700 -type d) ]]; then
                chmod 700 "$ssh_dir"
                echo "Change '$ssh_dir' permission to 700."
            else
                echo "'$ssh_dir' permission OK."
            fi
        else
            mkdir -m 700 "$ssh_dir"
            echo "Created directory '$ssh_dir'."
        fi
        echo.next_step
        echo 'Please create an SSH key pair, register the public key with GitHub.'
        echo
        echo '  ssh-keygen -t ed25519'
        echo
        echo 'And then re-run this script. Or set the DOTFILES_DOWNLOADER environment variable.'
        echo
        echo '  Specifiable commands:'
        echo '    - curl'
        echo '    - wget'
        echo
        exit 1
    }
    dotfiles_download_failed() { echo.abort 'Failed to dotfiles download;('; }
    dotfiles_download_complete() {
        echo.end_ok "Dotfiles download complete! (${DOTFILES_PATH})"
        return
    }
    dotfiles_download_git() {
        echo -n 'Testing SSH connection to git@github.com...'

        local result=$(ssh -o StrictHostKeyChecking=no -T git@github.com 2>&1) || true
        if echo "$result" | grep -q "$GITHUB_USERNAME"; then
            echo.ok
        else
            echo.failed
            echo.error "$(loginfo) $result"
            echo.end_warn 'Aborting dotfiles download:('
            termination_with_check_ssh
        fi

        if ! git clone --recursive -b "$DOTFILES_BRANCH" "$DOTFILES_SSH_URL" "$DOTFILES_PATH"
        then
            echo.error "$(loginfo) failed to clone the dotfiles repository"
            dotfiles_download_failed
        fi
    }
    dotfiles_download_curl_or_wget() {
        local result

        if ! cmd_exists_check 'tar'; then
            echo.error "$(loginfo) command is required: tar"
            dotfiles_download_failed
        fi

        if [[ -e $DOTFILES_PATH ]]; then
            if [[ -L $DOTFILES_PATH ]]; then
                echo.error "$(loginfo) symbolic link already exists: $DOTFILES_PATH"
                dotfiles_download_failed
            fi
            if ! result=$(find "$DOTFILES_PATH" -mindepth 1 2>&1); then
                echo.error "$(loginfo) $result"
                dotfiles_download_failed
            elif [[ -n $result ]]; then
                echo.error "$(loginfo) '${DOTFILES_PATH}' already exists and is not an empty directory"
                dotfiles_download_failed
            fi
            echo "Empty dotfiles directory exists: $DOTFILES_PATH"
        else
            if result=$(mkdir "$DOTFILES_PATH" 2>&1); then
                echo "Created directory '$DOTFILES_PATH'."
            else
                echo.error "$(loginfo) $result"
                dotfiles_download_failed
            fi
        fi

        case "$DOTFILES_DOWNLOADER" in
            curl) curl -L "$DOTFILES_TARBALL_URL" ;;
            wget) wget -O - "$DOTFILES_TARBALL_URL" ;;
        esac | tar xvz -C "$DOTFILES_PATH" --strip-components=1 || dotfiles_download_failed
    }

    echo.title 'Starting dotfiles download'

    if [[ -e $DOTFILES_PATH ]]; then
        echo.end_ok 'Dotfiles already exists:)'
        return
    fi

    check_downloader
    echo.section "Downloading with ${DOTFILES_DOWNLOADER}..."
    case "$DOTFILES_DOWNLOADER" in
        git)
           dotfiles_download_git ;;
        curl|wget)
           dotfiles_download_curl_or_wget ;;
        *)
           echo.error "$(loginfo) unknown downloader: $DOTFILES_DOWNLOADER"
           dotfiles_download_failed
           ;;
    esac
    dotfiles_download_complete
}

dotfiles_initialize() {
    initialize_package_manager() {
        install_homebrew() {
            if ! cmd_exists_check 'brew'; then
                echo.subsection 'Installing Homebrew...'
                if ! /bin/bash -c \
                     "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)";
                then
                    echo.abort 'Homebrew installation fialed;('
                fi
                echo.subsection 'Homebrew installation successful!'
            fi
        }
        echo.section 'Initializing package manager...'
        case "$PLATFORM" in
            mac)
               install_homebrew
               ;;
        esac
        echo.section 'Package manager initialization successful!'
    }
    install_requirements() {
        install_make() {
            case "$PLATFORM" in
                mac)
                   brew install make
                   ;;
            esac
        }
        echo.section 'Checking requirements...'
        cmd_exists_check -q 'make' || install_make
        check_make
    }
    install_packages() {
        install_brew_packages() {
            if ! cmd_exists_check -q 'brew'; then
                echo.abort "$(loginfo) command not found: brew"
            else
                make brew-pkg-install
                echo.section 'Homebrew packages installation successful!'
            fi
        }
        echo.section 'Installing packages...'
        case "$PLATFORM" in
            mac)
               install_brew_packages
               ;;
        esac
    }

    echo.title 'Starting initialization'
    case "$PLATFORM" in
        mac) ;;
        *)
           echo.end_warn "'$PLATFORM' is not supportedX("
           return
           ;;
    esac
    initialize_package_manager
    install_requirements
    install_packages
    echo.end_ok 'Initialization is complete!'
}

dotfiles_install() {
    echo.title 'Starting dotfiles installation'
    check_make
    make link
    make git-hooks
    cmd_exists_check -q 'git' && make git-setup
    echo.end_ok 'Dotfiles installation complete:D'
}


# main
GITHUB_USERNAME='6e-3'
[[ -z ${DOTFILES_BRANCH:-} ]] && DOTFILES_BRANCH='trunk'
DOTFILES_PATH="${HOME:?}/.dotfiles"
DOTFILES_SSH_URL="git@github.com:${GITHUB_USERNAME}/dotfiles.git"
DOTFILES_TARBALL_URL="https://github.com/${GITHUB_USERNAME}/dotfiles/archive/${DOTFILES_BRANCH}.tar.gz"
LIB_ECHO_PATH="${DOTFILES_PATH}/lib/bash/echo.bash"
LIB_ECHO_URL="https://raw.githubusercontent.com/${GITHUB_USERNAME}/dotfiles/${DOTFILES_BRANCH}/lib/bash/echo.bash"
PLATFORM=
MAKE_CHECKED=false

dotfiles_hello
platform_detection
dotfiles_download
cd "$DOTFILES_PATH"
if [[ -n ${DOTFILES_INIT-} ]]; then
    echo.attention 'The DOTFILES_INIT option has been selected.'
    printf "Press $(echo.sgr bold)RETURN/ENTER$(echo.sgr) to continue or press any other key to abort.\n"
    IFS='' read -sr -n 1 -p 'Ready?' input && echo
    if [[ -n $input ]]; then
        echo.end_warn 'Aborting the initialization:P'
    else
        echo
        dotfiles_initialize
    fi
fi
dotfiles_install
