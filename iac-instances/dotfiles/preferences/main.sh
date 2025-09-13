#!/bin/bash

cd "$(dirname "${BASH_SOURCE[0]}")" \
    && . "../utils.sh"

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

run_preferences() {
    local os_version=""
    local preferences_dir=""

    # Detect Ubuntu version
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        if [[ "$ID" == "ubuntu" ]]; then
            if [[ "$VERSION_ID" == "22.04" ]]; then
                os_version="ubuntu-22-svr"
            elif [[ "$VERSION_ID" == "24.04" ]]; then
                os_version="ubuntu-24-svr"
            else
                print_warning "Unsupported Ubuntu version: $VERSION_ID"
                print_warning "Using Ubuntu 22 server preferences as fallback"
                os_version="ubuntu-22-svr"
            fi
        fi
    fi

    if [ -z "$os_version" ]; then
        print_error "Unable to detect Ubuntu version"
        return 1
    fi

    preferences_dir="./$os_version"

    print_in_purple "\n • Setting preferences for $os_version\n\n"

    # Run preference scripts in order
    local scripts=(
        "privacy.sh"
        "terminal.sh"
        "ui_and_ux.sh"
    )

    for script in "${scripts[@]}"; do
        local script_path="$preferences_dir/$script"
        if [ -f "$script_path" ]; then
            print_in_purple "\n   Running $script\n\n"
            . "$script_path"
        else
            print_warning "$script not found for $os_version"
        fi
    done
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

main() {
    print_in_purple "\n • System Preferences\n\n"

    run_preferences

    print_in_purple "\n   Preferences configuration complete!\n"
}

main "$@"