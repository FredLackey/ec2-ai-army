#!/bin/bash

cd "$(dirname "${BASH_SOURCE[0]}")" \
    && . "../../utils.sh"

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

configure_terminal() {
    print_in_purple "\n   Terminal Configuration\n\n"

    # Set terminal type
    if ! grep -q "TERM=" "$HOME/.bashrc" 2>/dev/null; then
        execute "echo 'export TERM=xterm-256color' >> $HOME/.bashrc" \
            "Set terminal to 256 colors"
    else
        print_success "Terminal type already configured"
    fi

    # Configure readline
    local inputrc="$HOME/.inputrc"
    if [ -f "$inputrc" ]; then
        # Enable case-insensitive tab completion
        if ! grep -q "set completion-ignore-case" "$inputrc" 2>/dev/null; then
            echo "set completion-ignore-case on" >> "$inputrc"
            print_success "Enable case-insensitive completion"
        fi

        # Show all matches on ambiguous completion
        if ! grep -q "set show-all-if-ambiguous" "$inputrc" 2>/dev/null; then
            echo "set show-all-if-ambiguous on" >> "$inputrc"
            print_success "Show all matches on ambiguous completion"
        fi

        # Enable colored completion
        if ! grep -q "set colored-stats" "$inputrc" 2>/dev/null; then
            echo "set colored-stats on" >> "$inputrc"
            print_success "Enable colored completion stats"
        fi
    fi

    # Set default editor
    if ! grep -q "EDITOR=" "$HOME/.bashrc" 2>/dev/null; then
        execute "echo 'export EDITOR=vim' >> $HOME/.bashrc" \
            "Set default editor to vim"
    else
        print_success "Default editor already set"
    fi

    # Set default pager
    if ! grep -q "PAGER=" "$HOME/.bashrc" 2>/dev/null; then
        execute "echo 'export PAGER=less' >> $HOME/.bashrc" \
            "Set default pager to less"
    else
        print_success "Default pager already set"
    fi
}

configure_history() {
    print_in_purple "\n   History Configuration\n\n"

    # Increase history size
    if ! grep -q "HISTSIZE=" "$HOME/.bashrc" 2>/dev/null; then
        cat >> "$HOME/.bashrc" << 'EOF'

# History configuration
export HISTSIZE=10000
export HISTFILESIZE=20000
export HISTCONTROL=ignoreboth:erasedups
export HISTIGNORE="ls:ll:cd:pwd:exit:clear:history"
export HISTTIMEFORMAT="%F %T "
EOF
        print_success "Configure bash history"
    else
        print_success "History already configured"
    fi

    # Enable history appending
    if ! grep -q "shopt -s histappend" "$HOME/.bashrc" 2>/dev/null; then
        echo "shopt -s histappend" >> "$HOME/.bashrc"
        print_success "Enable history appending"
    fi
}

configure_locale() {
    print_in_purple "\n   Locale Configuration\n\n"

    # Set UTF-8 locale
    if ! locale | grep -q "UTF-8"; then
        execute "sudo locale-gen en_US.UTF-8" \
            "Generate UTF-8 locale"

        execute "sudo update-locale LANG=en_US.UTF-8" \
            "Set default locale to UTF-8"
    else
        print_success "UTF-8 locale already configured"
    fi

    # Set timezone (optional)
    local current_tz=$(timedatectl show -p Timezone --value 2>/dev/null)
    if [ "$current_tz" != "UTC" ]; then
        ask_for_confirmation "Set timezone to UTC?"
        if answer_is_yes; then
            execute "sudo timedatectl set-timezone UTC" \
                "Set timezone to UTC"
        fi
    else
        print_success "Timezone already set to UTC"
    fi
}

configure_ssh() {
    print_in_purple "\n   SSH Configuration\n\n"

    # Create SSH directory if it doesn't exist
    if [ ! -d "$HOME/.ssh" ]; then
        execute "mkdir -p $HOME/.ssh && chmod 700 $HOME/.ssh" \
            "Create SSH directory"
    else
        print_success "SSH directory exists"
    fi

    # Set proper permissions for SSH files
    if [ -f "$HOME/.ssh/authorized_keys" ]; then
        chmod 600 "$HOME/.ssh/authorized_keys"
        print_success "Set authorized_keys permissions"
    fi

    if [ -f "$HOME/.ssh/config" ]; then
        chmod 600 "$HOME/.ssh/config"
        print_success "Set SSH config permissions"
    fi

    # Create basic SSH config if it doesn't exist
    if [ ! -f "$HOME/.ssh/config" ]; then
        cat > "$HOME/.ssh/config" << 'EOF'
# SSH Configuration

# Global settings
Host *
    ServerAliveInterval 60
    ServerAliveCountMax 3
    TCPKeepAlive yes
    Compression yes
    ForwardAgent no
    ForwardX11 no
    HashKnownHosts yes
    StrictHostKeyChecking ask
    VisualHostKey yes

# GitHub
Host github.com
    HostName github.com
    User git
    IdentityFile ~/.ssh/id_ed25519
EOF
        chmod 600 "$HOME/.ssh/config"
        print_success "Created SSH config"
    else
        print_success "SSH config already exists"
    fi
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

main() {
    configure_terminal
    configure_history
    configure_locale
    configure_ssh
}

main "$@"