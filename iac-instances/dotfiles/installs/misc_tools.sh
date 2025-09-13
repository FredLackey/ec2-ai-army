#!/bin/bash

cd "$(dirname "${BASH_SOURCE[0]}")" \
    && . "../utils.sh"

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

install_development_tools() {
    print_in_purple "\n   Development Tools\n\n"

    # ShellCheck - Shell script linter
    if ! cmd_exists "shellcheck"; then
        install_package "ShellCheck" "shellcheck"
    else
        print_success "ShellCheck (already installed)"
    fi

    # Tree - Directory tree viewer
    if ! cmd_exists "tree"; then
        install_package "Tree" "tree"
    else
        print_success "Tree (already installed)"
    fi

    # Ripgrep - Fast search tool
    if ! cmd_exists "rg"; then
        install_package "Ripgrep" "ripgrep"
    else
        print_success "Ripgrep (already installed)"
    fi

    # FD - Modern find alternative
    if ! cmd_exists "fd"; then
        install_package "fd-find" "fd-find"
        # Create symlink for fd command
        if [ -f "/usr/bin/fdfind" ] && [ ! -f "/usr/local/bin/fd" ]; then
            execute "sudo ln -s /usr/bin/fdfind /usr/local/bin/fd" \
                "Create fd symlink"
        fi
    else
        print_success "fd (already installed)"
    fi

    # Bat - Cat with syntax highlighting
    if ! cmd_exists "bat"; then
        install_package "Bat" "bat"
        # Create symlink for bat command on Ubuntu
        if [ -f "/usr/bin/batcat" ] && [ ! -f "/usr/local/bin/bat" ]; then
            execute "sudo ln -s /usr/bin/batcat /usr/local/bin/bat" \
                "Create bat symlink"
        fi
    else
        print_success "Bat (already installed)"
    fi

    # Exa - Modern ls replacement
    if ! cmd_exists "exa"; then
        install_package "Exa" "exa"
    else
        print_success "Exa (already installed)"
    fi

    # FZF - Fuzzy finder
    if ! cmd_exists "fzf"; then
        install_package "FZF" "fzf"
    else
        print_success "FZF (already installed)"
    fi

    # Direnv - Environment variable manager
    if ! cmd_exists "direnv"; then
        install_package "Direnv" "direnv"
        # Add direnv hook to bashrc
        if [ -f "$HOME/.bashrc" ]; then
            if ! grep -q "direnv hook bash" "$HOME/.bashrc" 2>/dev/null; then
                echo 'eval "$(direnv hook bash)"' >> "$HOME/.bashrc"
                print_success "Added direnv hook to bashrc"
            fi
        fi
    else
        print_success "Direnv (already installed)"
    fi

    # TLDR - Simplified man pages
    if ! cmd_exists "tldr"; then
        install_package "TLDR" "tldr"
    else
        print_success "TLDR (already installed)"
    fi

    # HTTPie - Modern curl alternative
    if ! cmd_exists "http"; then
        install_package "HTTPie" "httpie"
    else
        print_success "HTTPie (already installed)"
    fi

    # Neofetch - System information tool
    if ! cmd_exists "neofetch"; then
        install_package "Neofetch" "neofetch"
    else
        print_success "Neofetch (already installed)"
    fi
}

install_python_tools() {
    print_in_purple "\n   Python Development Tools\n\n"

    # Python3 and pip
    if ! cmd_exists "python3"; then
        install_package "Python 3" "python3"
    else
        print_success "Python 3 (already installed)"
    fi

    if ! cmd_exists "pip3"; then
        install_package "Python 3 pip" "python3-pip"
    else
        print_success "pip3 (already installed)"
    fi

    # Python development headers
    install_package "Python 3 Dev" "python3-dev"

    # Virtual environment
    install_package "Python 3 venv" "python3-venv"

    # Python tools via pip
    if cmd_exists "pip3"; then
        # Pipenv
        if ! pip3 show pipenv &>/dev/null; then
            execute "pip3 install --user pipenv" "Install Pipenv"
        else
            print_success "Pipenv (already installed)"
        fi

        # Black formatter
        if ! pip3 show black &>/dev/null; then
            execute "pip3 install --user black" "Install Black formatter"
        else
            print_success "Black (already installed)"
        fi

        # Flake8 linter
        if ! pip3 show flake8 &>/dev/null; then
            execute "pip3 install --user flake8" "Install Flake8 linter"
        else
            print_success "Flake8 (already installed)"
        fi

        # IPython
        if ! pip3 show ipython &>/dev/null; then
            execute "pip3 install --user ipython" "Install IPython"
        else
            print_success "IPython (already installed)"
        fi
    fi
}

install_database_clients() {
    print_in_purple "\n   Database Clients\n\n"

    # PostgreSQL client
    install_package "PostgreSQL Client" "postgresql-client"

    # MySQL/MariaDB client
    install_package "MySQL Client" "mysql-client" || \
        install_package "MariaDB Client" "mariadb-client"

    # Redis client
    install_package "Redis Tools" "redis-tools"

    # SQLite
    if ! cmd_exists "sqlite3"; then
        install_package "SQLite 3" "sqlite3"
    else
        print_success "SQLite 3 (already installed)"
    fi
}

install_yarn_alternative() {
    print_in_purple "\n   Yarn Package Manager\n\n"

    # Check if yarn is already installed via npm
    if cmd_exists "yarn"; then
        print_success "Yarn (already installed)"
        return 0
    fi

    # Try to install via npm if available
    if cmd_exists "npm"; then
        execute "npm install -g yarn" "Install Yarn via npm"
        return 0
    fi

    # Alternative: Install via official repository
    if ! cmd_exists "yarn"; then
        # Add Yarn repository
        execute "curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -" \
            "Add Yarn GPG key"

        execute "echo 'deb https://dl.yarnpkg.com/debian/ stable main' | sudo tee /etc/apt/sources.list.d/yarn.list" \
            "Add Yarn repository"

        execute "sudo apt-get update" "Update package list"

        install_package "Yarn" "yarn --no-install-recommends"
    fi
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

main() {
    print_in_purple "\n • Development Tools\n\n"

    ask_for_sudo

    install_development_tools
    install_python_tools
    install_database_clients

    # Optional: Install Yarn if requested
    ask_for_confirmation "Do you want to install Yarn package manager?"
    if answer_is_yes; then
        install_yarn_alternative
    fi

    print_in_purple "\n   Development tools installation complete!\n"
}

main "$@"