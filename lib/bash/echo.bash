#!/bin/bash
#
# IMPORT:
#   - local:        source "${HOME}/.dotfiles/lib/bash/echo.bash"
#   - via network:  eval "$(curl -fsSL https://raw.githubusercontent.com/6e-3/dotfiles/trunk/lib/bash/echo.bash)"

if [ -z "${BASH_VERSION:-}" ]; then
    printf "$(basename "$0"): %s\n" "$@" >&2
    exit 1
fi

if [[ -t 1 ]]; then
    echo.escape() { printf "\033[%sm" "$1"; }
else
    echo.escape() { :; }
fi

echo.sgr() {
    usage() {
        echo 'USAGE: echo.sgr [option]'
        echo 'DESCRIPTION:'
        echo '    Print the ANSI escape code SGR(Select Graphic Rendition) parameter.'
        echo 'OPTIONS:'
        echo '  - Reset:'
        echo '      Omitting the option will reset the color and attributes.'
        echo '  - Colors:'
        echo '      black'
        echo '      red'
        echo '      green'
        echo '      yellow'
        echo '      blue'
        echo '      magenta'
        echo '      cyan'
        echo '      white'
        echo '      default'
        echo '  - Attributes:'
        echo '      reset_attr'
        echo '      bold'
        echo '      faint'
        echo '      italic'
        echo '      underline'
        echo '      blink'
        echo '      fast_blink'
        echo '      reverse'
        echo '      conceal'
        echo '      strike'
    }

    # colors
    local -r black='30'
    local -r red='31'
    local -r green='32'
    local -r yellow='33'
    local -r blue='34'
    local -r magenta='35'
    local -r cyan='36'
    local -r white='37'
    local -r default='39'

    # attributes
    local -r reset_attr='0'
    local -r bold='1'
    local -r faint='2'
    local -r italic='3'
    local -r underline='4'
    local -r blink='5'
    local -r fast_blink='6'
    local -r reverse='7'
    local -r conceal='8'
    local -r strike='9'
    local -r reset_all="${reset_attr};${default}"

    if [[ $# -eq 0 ]]; then
        echo.escape "$reset_all"
        return 0
    fi

    local code_color
    local code_attr_arr=()
    while (($# > 0)); do
        case $1 in
            # colors
            black)    code_color="$black";;
            red)      code_color="$red";;
            green)    code_color="$green";;
            yellow)   code_color="$yellow";;
            blue)     code_color="$blue";;
            magenta)  code_color="$magenta";;
            cyan)     code_color="$cyan";;
            white)    code_color="$white";;
            default)  code_color="$default";;
            [0-9]*)   code_color="38;5;$1";;
            # attributes
            reset_attr)  code_attr_arr+=("$reset_attr");;
            bold)        code_attr_arr+=("$bold");;
            italic)      code_attr_arr+=("$italic");;
            underline)   code_attr_arr+=("$underline");;
            blink)       code_attr_arr+=("$blink");;
            # others
            -h | --help)
                usage
                return 0;;
            *)
                echo "${FUNCNAME[0]}: illegal option: $1" >&2
                return 1;;
        esac
        shift
    done

    local -r code_attr_arr_len="${#code_attr_arr[@]}"
    if [[ $code_attr_arr_len -eq 0 ]]; then
        if [[ -z ${code_color:-} ]]; then
            echo "${FUNCNAME[0]}: option couldn't be detected" >&2
            return 1
        else
            printf '%s' "$(echo.escape "${code_color}")"
        fi
    else
        local -r code_attr=$(
            for attr in "${code_attr_arr[@]}"; do
                echo -n "${attr};"
            done)
        if [[ -z ${code_color:-} ]]; then
            printf '%s' "$(echo.escape "${code_attr%;}")"
        else
            printf '%s' "$(echo.escape "${code_attr}${code_color}")"
        fi
    fi
}

# variables
_echo_sleep=0.4
_echo_red=166
_echo_blue=75
_echo_yellow=220
_echo_lime=156
_echo_cyan=158
_echo_light_cyan=195
_echo_pink=175
_echo_gray=245
_echo_dark_green=30
_echo_purple=105

_echo_base="$_echo_cyan"
_echo_accent="$_echo_purple"

# formats
echo.msg() {
    printf "$(echo.sgr bold "$_echo_base")%s$(echo.sgr)\n" "$*"
    sleep "$_echo_sleep"
}
echo.attention() {
    local symbol='!'
    printf "$(echo.sgr bold "$_echo_yellow")$symbol $(echo.sgr default)%s$(echo.sgr)\n" "$*"
    sleep "$_echo_sleep"
}
echo.end_ok() { printf "✨$(echo.sgr bold "$_echo_pink")%s$(echo.sgr)\n\n" "$@"; }
echo.end_warn() { printf "$(echo.sgr bold "$_echo_yellow")%s$(echo.sgr)\n\n" "$@"; }
echo.abort() {
    printf "$(echo.sgr bold "$_echo_red")%s$(echo.sgr)\n" "$*"
    exit 1
}


# log formats
echo.debug() { printf "$(echo.sgr "$_echo_dark_green")DEBUG$(echo.sgr): %s\n" "$*"; }
echo.info()  { printf "$(echo.sgr 105)INFO$(echo.sgr): %s\n" "$*"; }
echo.warn()  { printf "$(echo.sgr "$_echo_yellow")WARN$(echo.sgr): %s\n" "$*" >&2; }
echo.error() { printf "$(echo.sgr "$_echo_red")ERROR$(echo.sgr): %s\n" "$*" >&2; }


# title formats
echo.title() {
    local loading_symbol
    local count=5
    for i in $(seq "$count"); do
        sleep 0.3
        loading_symbol=$(yes '.' | head -n "$i" | tr -d '\n') || true
        printf "\r$(echo.sgr bold "$_echo_base")> $(echo.sgr default)%s$(echo.sgr)$loading_symbol" "$*"
    done
    sleep "$_echo_sleep"
    echo
}
echo.section() {
    local symbol='>>>'
    printf "$(echo.sgr bold "$_echo_base")%s $(echo.sgr default)%s$(echo.sgr)\n" "$symbol" "$*"
    sleep "$_echo_sleep"
}
echo.subsection() {
    local symbol='==>'
    printf "$(echo.sgr bold "$_echo_purple")%s $(echo.sgr default)%s$(echo.sgr)\n" "$symbol" "$*"
    sleep 0.1
}
echo.next_step() {
    local symbol='>>>'
    printf "$(echo.sgr bold "$_echo_base")%s $(echo.sgr default)Next Steps...$(echo.sgr)\n" "$symbol"
    sleep "$_echo_sleep"
}


# processing result formats
echo.ok()       { printf "$(echo.sgr bold "$_echo_pink")OK$(echo.sgr)\n"; }
echo.failed()   { printf "$(echo.sgr bold "$_echo_red")FAILED$(echo.sgr)\n"; }
echo.notfound() { printf "$(echo.sgr bold "$_echo_red")NOT FOUND$(echo.sgr)\n"; }
echo.skip()     { printf "$(echo.sgr bold "$_echo_yellow")SKIP$(echo.sgr)\n"; }
echo.exist()    { printf "$(echo.sgr bold "$_echo_blue")EXIST$(echo.sgr)\n"; }


# others
echo.bar() {
    local count
    if [[ $# -eq 0 ]]; then
        count=80
    elif [[ $# -ne 1 || ! $1 =~ ^[1-9][0-9]*$ ]]; then
        echo "${FUNCNAME[0]}: invalid option" 2>&1
        return 1
    else
        count="$1"
    fi
    local bar
    local symbol='.'
    for i in $(seq "$count"); do
        sleep 0.002
        bar=$(yes "$symbol" | head -n "$i" | tr -d '\n') || true
        printf "\r$(echo.sgr bold "$_echo_base")%s$(echo.sgr)" "$bar"
    done
    echo
}
