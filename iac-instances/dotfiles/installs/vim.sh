#!/bin/bash

cd "$(dirname "${BASH_SOURCE[0]}")" \
    && . "../utils.sh"

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

install_vim() {
    # Check if vim is already installed
    if cmd_exists "vim"; then
        local vim_version=$(vim --version | head -1 | cut -d' ' -f5)
        print_success "Vim (already installed: $vim_version)"
    else
        # Install vim with additional features
        install_package "Vim" "vim"
    fi

    # Install vim-gtk3 for clipboard support (if in GUI environment)
    # Skip this for server environments
    if [ -n "$DISPLAY" ]; then
        install_package "Vim GTK3 (clipboard support)" "vim-gtk3"
    fi

    # Install dependencies for vim plugins
    install_package "exuberant-ctags" "exuberant-ctags"
    install_package "silversearcher-ag" "silversearcher-ag"
}

setup_vim_directories() {
    print_in_purple "\n   Vim Directories\n\n"

    # Create necessary vim directories
    mkd "$HOME/.vim"
    mkd "$HOME/.vim/backups"
    mkd "$HOME/.vim/swaps"
    mkd "$HOME/.vim/undos"
    mkd "$HOME/.vim/autoload"
    mkd "$HOME/.vim/plugged"

    # Set proper permissions
    chmod 700 "$HOME/.vim/backups" 2>/dev/null
    chmod 700 "$HOME/.vim/swaps" 2>/dev/null
    chmod 700 "$HOME/.vim/undos" 2>/dev/null

    print_success "Vim directories configured"
}

install_vim_plugins() {
    print_in_purple "\n   Vim Plugins\n\n"

    # Check if vim-plug is installed
    local PLUG_FILE="$HOME/.vim/autoload/plug.vim"
    if [ ! -f "$PLUG_FILE" ]; then
        execute "curl -fLo $PLUG_FILE --create-dirs \
            https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim" \
            "Install vim-plug"
    else
        print_success "vim-plug already installed"
    fi

    # Install/update plugins using vim
    if cmd_exists "vim" && [ -f "$HOME/.vimrc" ]; then
        print_in_purple "\n   Installing Vim plugins (this may take a moment)\n\n"

        # Install plugins in headless mode
        vim +PlugInstall +qall &>/dev/null

        # Update plugins
        vim +PlugUpdate +qall &>/dev/null

        print_success "Vim plugins installed/updated"
    fi
}

install_vim_language_servers() {
    print_in_purple "\n   Language Servers for Vim\n\n"

    # Install language servers for better code intelligence
    # These are optional but enhance the vim experience

    # Python
    if cmd_exists "python3"; then
        if cmd_exists "pip3"; then
            if ! pip3 show pylint &>/dev/null; then
                execute "pip3 install --user pylint" "Install pylint (Python linter)"
            else
                print_success "pylint already installed"
            fi

            if ! pip3 show black &>/dev/null; then
                execute "pip3 install --user black" "Install black (Python formatter)"
            else
                print_success "black already installed"
            fi
        fi
    fi

    # JavaScript/TypeScript (if node is available)
    if cmd_exists "npm"; then
        if ! npm list -g eslint &>/dev/null; then
            execute "npm install -g eslint" "Install ESLint"
        else
            print_success "ESLint already installed"
        fi

        if ! npm list -g prettier &>/dev/null; then
            execute "npm install -g prettier" "Install Prettier"
        else
            print_success "Prettier already installed"
        fi
    fi

    # Shell
    if ! cmd_exists "shellcheck"; then
        install_package "ShellCheck" "shellcheck"
    else
        print_success "ShellCheck already installed"
    fi
}

configure_vim() {
    print_in_purple "\n   Vim Configuration\n\n"

    # Create a local vimrc for machine-specific settings
    local LOCAL_VIMRC="$HOME/.vimrc.local"
    if [ ! -f "$LOCAL_VIMRC" ]; then
        cat > "$LOCAL_VIMRC" << 'EOF'
" Local vim configuration
" Add machine-specific vim settings here

" Example: Set specific colorscheme
" colorscheme desert

" Example: Set specific font for GUI
" if has('gui_running')
"     set guifont=Monaco:h12
" endif
EOF
        print_success "Created local vimrc"
    else
        print_success "Local vimrc already exists"
    fi

    # Check if vimrc sources the local config
    if [ -f "$HOME/.vimrc" ]; then
        if ! grep -q "source.*vimrc.local" "$HOME/.vimrc" 2>/dev/null; then
            echo "" >> "$HOME/.vimrc"
            echo '" Source local configuration' >> "$HOME/.vimrc"
            echo 'if filereadable(expand("~/.vimrc.local"))' >> "$HOME/.vimrc"
            echo '    source ~/.vimrc.local' >> "$HOME/.vimrc"
            echo 'endif' >> "$HOME/.vimrc"
            print_success "Added local config sourcing to vimrc"
        else
            print_success "Local config sourcing already configured"
        fi
    fi
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

main() {
    print_in_purple "\n • Vim\n\n"

    install_vim
    setup_vim_directories
    configure_vim
    install_vim_plugins
    install_vim_language_servers

    print_in_purple "\n   Vim installation complete!\n"
}

main "$@"