#!/bin/bash

cd "$(dirname "${BASH_SOURCE[0]}")" \
    && . "../utils.sh"

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

install_core_packages() {
    print_in_purple "\n   Core System Packages\n\n"

    # Debian Archive Keyring
    install_package "Debian Archive Keyring" "debian-archive-keyring"

    # CA Certificates
    if ! package_is_installed "ca-certificates"; then
        install_package "CA Certificates" "ca-certificates"
    else
        print_success "CA Certificates (already installed)"
    fi

    # Curl
    if ! cmd_exists "curl"; then
        install_package "cURL" "curl"
    else
        print_success "cURL (already installed)"
    fi

    # Wget
    if ! cmd_exists "wget"; then
        install_package "wget" "wget"
    else
        print_success "wget (already installed)"
    fi

    # Software Properties Common
    install_package "Software Properties Common" "software-properties-common"

    # GNU Privacy Guard
    install_package "GnuPG" "gnupg"

    # APT transport for HTTPS
    install_package "APT HTTPS Transport" "apt-transport-https"

    # LSB Release
    install_package "LSB Release" "lsb-release"
}

install_archive_tools() {
    print_in_purple "\n   Archive Tools\n\n"

    # Unzip
    if ! cmd_exists "unzip"; then
        install_package "Unzip" "unzip"
    else
        print_success "Unzip (already installed)"
    fi

    # Zip
    if ! cmd_exists "zip"; then
        install_package "Zip" "zip"
    else
        print_success "Zip (already installed)"
    fi

    # P7zip
    install_package "P7zip" "p7zip-full"

    # Unrar (if available in repositories)
    install_package "Unrar" "unrar" || install_package "Unrar-free" "unrar-free"

    # Tar (usually pre-installed but let's make sure)
    if ! cmd_exists "tar"; then
        install_package "Tar" "tar"
    else
        print_success "Tar (already installed)"
    fi
}

install_network_tools() {
    print_in_purple "\n   Network Tools\n\n"

    # Net-tools (provides ifconfig, netstat, etc.)
    install_package "Net Tools" "net-tools"

    # IPUtils (provides ping, traceroute, etc.)
    install_package "IPUtils" "iputils-ping"

    # DNS utilities
    install_package "DNS Utils" "dnsutils"

    # Netcat
    install_package "Netcat" "netcat"

    # OpenSSH Client
    if ! cmd_exists "ssh"; then
        install_package "OpenSSH Client" "openssh-client"
    else
        print_success "OpenSSH Client (already installed)"
    fi

    # Rsync
    if ! cmd_exists "rsync"; then
        install_package "Rsync" "rsync"
    else
        print_success "Rsync (already installed)"
    fi
}

install_system_monitoring() {
    print_in_purple "\n   System Monitoring Tools\n\n"

    # Htop
    if ! cmd_exists "htop"; then
        install_package "Htop" "htop"
    else
        print_success "Htop (already installed)"
    fi

    # IOTop
    install_package "IOTop" "iotop"

    # IFTop
    install_package "IFTop" "iftop"

    # NCurses Disk Usage
    if ! cmd_exists "ncdu"; then
        install_package "NCurses Disk Usage" "ncdu"
    else
        print_success "NCurses Disk Usage (already installed)"
    fi

    # Sysstat (provides sar, iostat, mpstat, etc.)
    install_package "Sysstat" "sysstat"
}

install_text_processing() {
    print_in_purple "\n   Text Processing Tools\n\n"

    # Awk (usually pre-installed)
    if ! cmd_exists "awk"; then
        install_package "GNU Awk" "gawk"
    else
        print_success "Awk (already installed)"
    fi

    # Sed (usually pre-installed)
    if ! cmd_exists "sed"; then
        install_package "GNU Sed" "sed"
    else
        print_success "Sed (already installed)"
    fi

    # Grep (usually pre-installed)
    if ! cmd_exists "grep"; then
        install_package "GNU Grep" "grep"
    else
        print_success "Grep (already installed)"
    fi

    # Jq (JSON processor)
    if ! cmd_exists "jq"; then
        install_package "jq (JSON processor)" "jq"
    else
        print_success "jq (already installed)"
    fi

    # XMLStarlet
    install_package "XMLStarlet" "xmlstarlet"

    # Pandoc (document converter)
    install_package "Pandoc" "pandoc"
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

main() {
    print_in_purple "\n • Miscellaneous Tools\n\n"

    ask_for_sudo

    install_core_packages
    install_archive_tools
    install_network_tools
    install_system_monitoring
    install_text_processing

    print_in_purple "\n   Miscellaneous tools installation complete!\n"
}

main "$@"