#!/bin/bash

# Color output functions
print_in_color() {
    printf "%b" \
        "$(tput setaf "$2" 2> /dev/null)" \
        "$1" \
        "$(tput sgr0 2> /dev/null)"
}

print_in_green() {
    print_in_color "$1" 2
}

print_in_purple() {
    print_in_color "$1" 5
}

print_in_red() {
    print_in_color "$1" 1
}

print_in_yellow() {
    print_in_color "$1" 3
}

print_error() {
    print_in_red "   [] $1 $2\n"
}

print_success() {
    print_in_green "   [] $1\n"
}

print_warning() {
    print_in_yellow "   [!] $1\n"
}

print_question() {
    print_in_yellow "   [?] $1"
}

print_result() {
    if [ "$1" -eq 0 ]; then
        print_success "$2"
    else
        print_error "$2"
    fi
    return "$1"
}

# Command execution with output handling
execute() {
    local -r CMDS="$1"
    local -r MSG="${2:-$1}"
    local -r TMP_FILE="$(mktemp /tmp/XXXXX)"
    local exitCode=0

    # Execute command and capture output
    eval "$CMDS" &> "$TMP_FILE"
    exitCode=$?

    # Print result
    print_result $exitCode "$MSG"

    if [ $exitCode -ne 0 ]; then
        # Show error output if command failed
        print_in_red "   � ERROR: "
        cat "$TMP_FILE"
    fi

    rm -rf "$TMP_FILE"
    return $exitCode
}

# Check if command exists
cmd_exists() {
    command -v "$1" &> /dev/null
}

# Package management for Ubuntu
package_is_installed() {
    dpkg -s "$1" &> /dev/null
}

install_package() {
    local PACKAGE_READABLE_NAME="$1"
    local PACKAGE="$2"
    local EXTRA_ARGUMENTS="${3:-}"

    if ! package_is_installed "$PACKAGE"; then
        execute "sudo apt-get install -y $EXTRA_ARGUMENTS $PACKAGE" "$PACKAGE_READABLE_NAME"
    else
        print_success "$PACKAGE_READABLE_NAME (already installed)"
    fi
}

update_system() {
    execute "sudo apt-get update -y" "APT (update)"
}

upgrade_system() {
    execute "export DEBIAN_FRONTEND=\"noninteractive\" && sudo apt-get -o Dpkg::Options::=\"--force-confnew\" upgrade -y" "APT (upgrade)"
}

autoremove() {
    execute "sudo apt-get autoremove -y" "APT (autoremove)"
}

# Directory creation
mkd() {
    if [ -n "$1" ]; then
        if [ -e "$1" ]; then
            if [ ! -d "$1" ]; then
                print_error "$1 - a file with the same name already exists!"
            else
                print_success "$1 (already exists)"
            fi
        else
            execute "mkdir -p $1" "$1"
        fi
    fi
}

# Ask for sudo upfront
ask_for_sudo() {
    # Ask for the administrator password upfront
    sudo -v &> /dev/null

    # Update existing sudo time stamp until script has finished
    while true; do
        sudo -n true
        sleep 60
        kill -0 "$$" || exit
    done &> /dev/null &
}

# Get OS information
get_os() {
    local os=""
    local kernelName=""

    kernelName="$(uname -s)"

    if [ "$kernelName" == "Darwin" ]; then
        os="macos"
    elif [ "$kernelName" == "Linux" ] && [ -e "/etc/os-release" ]; then
        os="$(. /etc/os-release; printf "%s" "$ID")"
    else
        os="$kernelName"
    fi

    printf "%s" "$os"
}

get_os_version() {
    local os=""
    local version=""

    os="$(get_os)"

    if [ "$os" == "macos" ]; then
        version="$(sw_vers -productVersion)"
    elif [ -e "/etc/os-release" ]; then
        version="$(. /etc/os-release; printf "%s" "$VERSION_ID")"
    fi

    printf "%s" "$version"
}

# User confirmation helpers
ask() {
    print_question "$1"
    read -r
}

ask_for_confirmation() {
    print_question "$1 (y/n) "
    read -r -n 1
    printf "\n"
}

answer_is_yes() {
    [[ "$REPLY" =~ ^[Yy]$ ]] && return 0 || return 1
}

get_answer() {
    printf "%s" "$REPLY"
}

# Add content to file if it doesn't exist
add_to_file_if_not_exists() {
    local file="$1"
    local content="$2"
    local marker="$3"

    if [ -f "$file" ]; then
        if ! grep -q "$marker" "$file" 2>/dev/null; then
            printf "\n%s\n" "$content" >> "$file"
            return 0
        fi
    else
        printf "%s\n" "$content" > "$file"
        return 0
    fi
    return 1
}

# Copy file with backup
copy_with_backup() {
    local source="$1"
    local dest="$2"

    if [ -f "$dest" ]; then
        cp "$dest" "${dest}.backup.$(date +%Y%m%d_%H%M%S)"
    fi
    cp "$source" "$dest"
}

# Check if in git repository
is_git_repository() {
    git rev-parse &> /dev/null
}

# Skip questions flag handler
skip_questions() {
    while :; do
        case $1 in
            -y|--yes) return 0;;
                   *) break;;
        esac
        shift 1
    done
    return 1
}

# Get OS name for display
get_os_name() {
    local os=""
    local kernelName=""

    kernelName="$(uname -s)"

    if [ "$kernelName" == "Darwin" ]; then
        os="macOS"
    elif [ "$kernelName" == "Linux" ] && [ -e "/etc/os-release" ]; then
        os="$(. /etc/os-release; printf "%s" "$NAME")"
    else
        os="$kernelName"
    fi

    printf "%s" "$os"
}

# Check version support
is_supported_version() {
    # shellcheck disable=SC2206
    declare -a v1=(${1//./ })
    # shellcheck disable=SC2206
    declare -a v2=(${2//./ })
    local i=""

    # Fill empty positions in v1 with zeros
    for (( i=${#v1[@]}; i<${#v2[@]}; i++ )); do
        v1[i]=0
    done

    for (( i=0; i<${#v1[@]}; i++ )); do
        # Fill empty positions in v2 with zeros
        if [[ -z ${v2[i]} ]]; then
            v2[i]=0
        fi

        if (( 10#${v1[i]} < 10#${v2[i]} )); then
            return 1
        elif (( 10#${v1[i]} > 10#${v2[i]} )); then
            return 0
        fi
    done
}

# Kill all subprocesses
kill_all_subprocesses() {
    local i=""

    for i in $(jobs -p); do
        kill "$i"
        wait "$i" &> /dev/null
    done
}

# Set trap for script cleanup
set_trap() {
    trap -p "$1" | grep "$2" &> /dev/null \
        || trap '$2' "$1"
}

# Show spinner for long running commands
show_spinner() {
    local -r FRAMES='/-\|'
    local -r NUMBER_OF_FRAMES=${#FRAMES}
    local -r CMDS="$2"
    local -r MSG="$3"
    local -r PID="$1"
    local i=0
    local frameText=""

    # Display spinner while process is running
    while kill -0 "$PID" &>/dev/null; do
        frameText="   [${FRAMES:i++%NUMBER_OF_FRAMES:1}] $MSG"
        printf "%s" "$frameText"
        sleep 0.2
        printf "\r"
    done
}