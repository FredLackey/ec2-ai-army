#!/bin/bash

cd "$(dirname "${BASH_SOURCE[0]}")" \
    && . "../utils.sh"

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

install_tmux() {
    # Check if tmux is already installed
    if cmd_exists "tmux"; then
        print_success "Tmux (already installed: $(tmux -V | cut -d' ' -f2))"
    else
        install_package "Tmux" "tmux"
    fi

    # Install additional tmux-related tools
    install_package "xclip (clipboard support)" "xclip"
}

install_tpm() {
    local TPM_DIR="$HOME/.tmux/plugins/tpm"

    print_in_purple "\n   Tmux Plugin Manager (TPM)\n\n"

    # Check if TPM is already installed
    if [ -d "$TPM_DIR" ]; then
        print_success "TPM already installed"

        # Update TPM
        execute "cd $TPM_DIR && git pull" "Update TPM"
    else
        # Clone TPM
        execute "git clone https://github.com/tmux-plugins/tpm $TPM_DIR" \
            "Install TPM"
    fi

    # Install plugins
    if [ -f "$HOME/.tmux.conf" ] && [ -d "$TPM_DIR" ]; then
        print_in_purple "\n   Installing Tmux plugins\n\n"

        # Source tmux config and install plugins
        if cmd_exists "tmux"; then
            # Start a tmux server if not running
            tmux start-server 2>/dev/null || true

            # Install plugins
            execute "$TPM_DIR/bin/install_plugins" "Install tmux plugins"
        fi
    fi
}

configure_tmux() {
    print_in_purple "\n   Tmux Configuration\n\n"

    # Create tmux directories if they don't exist
    mkd "$HOME/.tmux"
    mkd "$HOME/.tmux/plugins"

    # Create a local tmux config for machine-specific settings
    local LOCAL_CONFIG="$HOME/.tmux.conf.local"
    if [ ! -f "$LOCAL_CONFIG" ]; then
        cat > "$LOCAL_CONFIG" << 'EOF'
# Local tmux configuration
# Add machine-specific tmux settings here

# Example: Set different prefix key
# set -g prefix C-a
# unbind C-b
# bind C-a send-prefix

# Example: Set status bar color
# set -g status-bg colour235
# set -g status-fg colour136
EOF
        print_success "Created local tmux config"
    else
        print_success "Local tmux config already exists"
    fi

    # Check if tmux.conf sources the local config
    if [ -f "$HOME/.tmux.conf" ]; then
        if ! grep -q "source.*tmux.conf.local" "$HOME/.tmux.conf" 2>/dev/null; then
            echo "" >> "$HOME/.tmux.conf"
            echo "# Source local configuration" >> "$HOME/.tmux.conf"
            echo "if-shell '[ -f ~/.tmux.conf.local ]' 'source ~/.tmux.conf.local'" >> "$HOME/.tmux.conf"
            print_success "Added local config sourcing to tmux.conf"
        else
            print_success "Local config sourcing already configured"
        fi
    fi
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

main() {
    print_in_purple "\n • Tmux\n\n"

    install_tmux
    configure_tmux
    install_tpm

    print_in_purple "\n   Tmux installation complete!\n"
    print_result $? "Note: Press 'prefix + I' inside tmux to install plugins"
}

main "$@"