#!/bin/bash

cd "$(dirname "${BASH_SOURCE[0]}")" && . "../utils.sh"

main() {
    print_in_purple "\n   Build Essentials\n\n"

    # Core build tools
    install_package "Build Essential" "build-essential"
    install_package "GCC" "gcc"
    install_package "G++" "g++"
    install_package "Make" "make"
    install_package "CMake" "cmake"

    # Development libraries
    install_package "SSL Development Files" "libssl-dev"
    install_package "Curl Development Files" "libcurl4-openssl-dev"
    install_package "XML Development Files" "libxml2-dev"
    install_package "Readline Development Files" "libreadline-dev"

    # Archive tools
    install_package "GnuPG" "gnupg"
    install_package "Debian Archive Keyring" "debian-archive-keyring"
    install_package "CA Certificates" "ca-certificates"
    install_package "Software Properties Common" "software-properties-common"
    install_package "APT Transport HTTPS" "apt-transport-https"

    # Python development
    install_package "Python 3" "python3"
    install_package "Python 3 pip" "python3-pip"
    install_package "Python 3 venv" "python3-venv"
    install_package "Python 3 dev" "python3-dev"

    # Version control
    install_package "Git" "git"
    install_package "Git LFS" "git-lfs"

    # Other essential tools
    install_package "Wget" "wget"
    install_package "Curl" "curl"
    install_package "Unzip" "unzip"
    install_package "Zip" "zip"
    install_package "Tar" "tar"
    install_package "Gzip" "gzip"
    install_package "Bzip2" "bzip2"
    install_package "XZ Utils" "xz-utils"
    install_package "LSB Release" "lsb-release"
}

main "$@"