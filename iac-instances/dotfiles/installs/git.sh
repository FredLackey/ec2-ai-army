#!/bin/bash

cd "$(dirname "${BASH_SOURCE[0]}")" \
    && . "../utils.sh"

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

install_git() {
    # Check if git is already installed
    if cmd_exists "git"; then
        print_success "Git (already installed: $(git --version | cut -d' ' -f3))"
        return 0
    fi

    # Install git
    install_package "Git" "git"

    # Install git extras if available
    install_package "Git Extras" "git-extras" "--no-install-recommends"

    # Install git-flow
    install_package "Git Flow" "git-flow"
}

configure_git() {
    print_in_purple "\n   Git Configuration\n\n"

    # Set up some basic git configurations
    if cmd_exists "git"; then
        # Check if user.name is configured
        if ! git config --global user.name > /dev/null 2>&1; then
            print_warning "Git user.name not configured. Run setup_github_ssh.sh to configure"
        fi

        # Check if user.email is configured
        if ! git config --global user.email > /dev/null 2>&1; then
            print_warning "Git user.email not configured. Run setup_github_ssh.sh to configure"
        fi

        # Set some sensible defaults
        execute "git config --global init.defaultBranch main" \
            "Set default branch to 'main'"

        execute "git config --global core.editor vim" \
            "Set default editor to vim"

        execute "git config --global color.ui auto" \
            "Enable colored output"

        execute "git config --global push.default simple" \
            "Set push behavior to 'simple'"

        execute "git config --global pull.rebase false" \
            "Set pull behavior to merge"

        execute "git config --global fetch.prune true" \
            "Enable automatic pruning on fetch"

        execute "git config --global diff.colorMoved zebra" \
            "Enable colored moved lines in diffs"

        execute "git config --global rebase.autoStash true" \
            "Enable auto-stashing on rebase"

        execute "git config --global merge.conflictstyle diff3" \
            "Show common ancestor in merge conflicts"
    fi
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

main() {
    print_in_purple "\n • Git\n\n"

    install_git
    configure_git

    print_in_purple "\n   Git installation complete!\n\n"
}

main "$@"