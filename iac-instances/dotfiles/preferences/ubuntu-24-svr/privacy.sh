#!/bin/bash

cd "$(dirname "${BASH_SOURCE[0]}")" \
    && . "../../utils.sh"

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

disable_telemetry() {
    print_in_purple "\n   Privacy Settings\n\n"

    # Disable Ubuntu telemetry
    if [ -f "/etc/default/apport" ]; then
        execute "sudo sed -i 's/enabled=1/enabled=0/g' /etc/default/apport" \
            "Disable error reporting"
    fi

    # Disable popularity contest
    if [ -f "/etc/popularity-contest.conf" ]; then
        execute "sudo sed -i 's/PARTICIPATE=\"yes\"/PARTICIPATE=\"no\"/g' /etc/popularity-contest.conf" \
            "Disable popularity contest"
    fi

    # Remove Amazon integration (if exists)
    if package_is_installed "ubuntu-web-launchers"; then
        execute "sudo apt-get remove -y ubuntu-web-launchers" \
            "Remove Amazon integration"
    fi

    # Disable motd news
    if [ -f "/etc/default/motd-news" ]; then
        execute "sudo sed -i 's/ENABLED=1/ENABLED=0/g' /etc/default/motd-news" \
            "Disable motd news"
    fi

    # Disable snapd telemetry (if snap is installed)
    if cmd_exists "snap"; then
        execute "sudo snap set system refresh.retain=2" \
            "Limit snap data retention"
    fi
}

configure_firewall() {
    print_in_purple "\n   Basic Firewall Configuration\n\n"

    # Note: We're NOT installing UFW as per the TODO exclusions
    # This is just for informational purposes

    print_warning "Firewall configuration skipped (not needed for dev servers)"
    print_warning "If you need firewall, manually install and configure UFW"
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

main() {
    disable_telemetry
    configure_firewall
}

main "$@"