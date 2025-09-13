#!/bin/bash

#############################################################################
# Ubuntu Server Setup Script for EC2 Instances
#############################################################################
# This script sets up a fresh Ubuntu server instance with:
# - Shell environment and dotfiles
# - Development tools (Git, Vim, Tmux)
# - Build essentials and system tools
# - Node.js via NVM
# - Docker and Docker Compose
# - System preferences and optimizations
#############################################################################

set -e  # Exit on error

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source utility functions
. "$SCRIPT_DIR/utils.sh"

# Configuration
BACKUP_DIR="$HOME/.config-backups/$(date +%Y%m%d_%H%M%S)"
LOG_FILE="/tmp/setup_$(date +%Y%m%d_%H%M%S).log"

# Redirect output to log file while still showing on screen
exec > >(tee -a "$LOG_FILE")
exec 2>&1

#############################################################################
# Functions
#############################################################################

print_banner() {
    cat << "EOF"

    ╔══════════════════════════════════════════════════════════════╗
    ║                                                              ║
    ║     Ubuntu Server Setup for AI Army EC2 Instances           ║
    ║                                                              ║
    ║     This script will configure your development             ║
    ║     environment with all necessary tools and settings       ║
    ║                                                              ║
    ╚══════════════════════════════════════════════════════════════╝

EOF

    print_in_purple "   Configuration:\n"
    echo "   • Script Directory: $SCRIPT_DIR"
    echo "   • Backup Directory: $BACKUP_DIR"
    echo "   • Log File: $LOG_FILE"
    echo ""
    print_in_purple "   Detected Environment:\n"
    echo "   • OS: $(get_os_name)"
    echo "   • Version: $(get_os_version)"
    echo "   • Architecture: $(uname -m)"
    echo "   • Hostname: $(hostname)"
    echo ""
}

check_os() {
    print_in_purple "\n • Checking OS compatibility\n\n"

    local os=$(get_os)
    local version=$(get_os_version)

    if [[ "$os" != "ubuntu" ]]; then
        print_error "This script is designed for Ubuntu only"
        print_error "Detected OS: $os"
        exit 1
    fi

    if [[ "$version" != "22.04" ]] && [[ "$version" != "24.04" ]]; then
        print_warning "This script is tested on Ubuntu 22.04 and 24.04"
        print_warning "Your version: $version"
        ask_for_confirmation "Continue anyway?"
        if ! answer_is_yes; then
            print_error "Setup cancelled"
            exit 1
        fi
    fi

    print_success "OS check passed: Ubuntu $version"
}

create_directories() {
    print_in_purple "\n • Creating necessary directories\n\n"

    # Create backup directory
    mkd "$BACKUP_DIR"

    # Create common directories
    mkd "$HOME/.local/bin"
    mkd "$HOME/.config"
    mkd "$HOME/workspace"
    mkd "$HOME/scripts"
}

run_system_update() {
    print_in_purple "\n • System Update\n\n"

    ask_for_confirmation "Update system packages?"
    if answer_is_yes; then
        update_system
        upgrade_system
    else
        print_warning "Skipping system update"
    fi
}

install_phase() {
    local phase="$1"
    local description="$2"
    local scripts=("${@:3}")

    print_in_purple "\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n"
    print_in_purple " $phase: $description\n"
    print_in_purple "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n\n"

    for script in "${scripts[@]}"; do
        local script_path="$SCRIPT_DIR/installs/$script"
        if [ -f "$script_path" ] && [ -x "$script_path" ]; then
            print_in_purple " • Running $script\n\n"
            . "$script_path"
        else
            print_warning " • Skipping $script (not found or not executable)"
        fi
    done
}

setup_dotfiles() {
    print_in_purple "\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n"
    print_in_purple " Setting up Dotfiles\n"
    print_in_purple "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n\n"

    # Create symbolic links
    if [ -f "$SCRIPT_DIR/create_symbolic_links.sh" ]; then
        print_in_purple " • Creating symbolic links\n\n"
        . "$SCRIPT_DIR/create_symbolic_links.sh" -y
    else
        print_warning " • Symbolic links script not found"
    fi
}

setup_preferences() {
    print_in_purple "\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n"
    print_in_purple " System Preferences\n"
    print_in_purple "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n\n"

    if [ -f "$SCRIPT_DIR/preferences/main.sh" ]; then
        . "$SCRIPT_DIR/preferences/main.sh"
    else
        print_warning " • Preferences script not found"
    fi
}

setup_github_ssh() {
    print_in_purple "\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n"
    print_in_purple " GitHub SSH Configuration\n"
    print_in_purple "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n\n"

    ask_for_confirmation "Setup GitHub SSH keys?"
    if answer_is_yes; then
        if [ -f "$SCRIPT_DIR/git/setup_github_ssh.sh" ]; then
            . "$SCRIPT_DIR/git/setup_github_ssh.sh"
        else
            print_warning " • GitHub SSH setup script not found"
        fi
    else
        print_warning " • Skipping GitHub SSH setup"
    fi
}

run_cleanup() {
    print_in_purple "\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n"
    print_in_purple " System Cleanup\n"
    print_in_purple "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n\n"

    ask_for_confirmation "Run system cleanup?"
    if answer_is_yes; then
        if [ -f "$SCRIPT_DIR/installs/cleanup.sh" ]; then
            . "$SCRIPT_DIR/installs/cleanup.sh"
        fi
    else
        print_warning " • Skipping cleanup"
    fi
}

print_summary() {
    print_in_purple "\n╔══════════════════════════════════════════════════════════════╗\n"
    print_in_purple "║                    Setup Complete!                          ║\n"
    print_in_purple "╚══════════════════════════════════════════════════════════════╝\n\n"

    print_in_green "   ✓ System configuration complete\n"
    print_in_green "   ✓ Development tools installed\n"
    print_in_green "   ✓ Dotfiles configured\n\n"

    print_in_purple "   Next Steps:\n"
    echo "   1. Restart your shell or run: source ~/.bashrc"
    echo "   2. Configure Git with your name and email"
    echo "   3. Add your SSH key to GitHub (if not done)"
    echo "   4. Clone your projects to ~/workspace"
    echo ""

    print_in_purple "   Useful Commands:\n"
    echo "   • tmux            - Start terminal multiplexer"
    echo "   • vim             - Enhanced text editor"
    echo "   • git             - Version control"
    echo "   • docker          - Container management"
    echo "   • nvm             - Node version management"
    echo ""

    print_in_purple "   Log file saved to: $LOG_FILE\n\n"
}

#############################################################################
# Main Installation Flow
#############################################################################

main() {
    # Initial setup
    print_banner
    check_os
    ask_for_sudo
    create_directories
    run_system_update

    # Phase 1: Core System Tools
    install_phase "Phase 1" "Core System Tools" \
        "build_essentials.sh" \
        "misc.sh" \
        "utilities.sh"

    # Phase 2: Development Tools
    install_phase "Phase 2" "Development Tools" \
        "git.sh" \
        "vim.sh" \
        "tmux.sh" \
        "misc_tools.sh"

    # Phase 3: Programming Environments
    install_phase "Phase 3" "Programming Environments" \
        "nvm.sh" \
        "npm.sh" \
        "docker.sh"

    # Phase 4: Configuration
    setup_dotfiles
    setup_preferences
    setup_github_ssh

    # Final cleanup
    run_cleanup

    # Show summary
    print_summary
}

# Handle script interruption
trap 'print_error "Setup interrupted"; exit 1' INT TERM

# Run main function
main "$@"

# Return success
exit 0