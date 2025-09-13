#!/bin/bash

cd "$(dirname "${BASH_SOURCE[0]}")" && . "../utils.sh"

declare -r NVM_DIRECTORY="$HOME/.nvm"
declare -r NVM_GIT_REPO_URL="https://github.com/nvm-sh/nvm.git"
declare -r NODE_VERSION="20"  # LTS version

add_nvm_configs() {
    local LOCAL_SHELL_CONFIG_FILE="$HOME/.bashrc"

    declare -r CONFIGS="
# Node Version Manager
export NVM_DIR=\"$NVM_DIRECTORY\"
[ -s \"\$NVM_DIR/nvm.sh\" ] && \\. \"\$NVM_DIR/nvm.sh\"
[ -s \"\$NVM_DIR/bash_completion\" ] && \\. \"\$NVM_DIR/bash_completion\"
"

    # Add NVM configuration to bashrc if not already present
    if ! grep -q "NVM_DIR" "$LOCAL_SHELL_CONFIG_FILE" 2>/dev/null; then
        execute "printf '%s' '$CONFIGS' >> $LOCAL_SHELL_CONFIG_FILE" \
            "Add NVM to $LOCAL_SHELL_CONFIG_FILE"
    else
        print_success "NVM config already in $LOCAL_SHELL_CONFIG_FILE"
    fi
}

install_latest_stable_node() {
    # Load NVM and install Node
    execute ". $NVM_DIRECTORY/nvm.sh && nvm install $NODE_VERSION && nvm alias default $NODE_VERSION && nvm use default" \
        "Install Node.js v$NODE_VERSION"
}

install_nvm() {
    # Install NVM
    execute "git clone --quiet $NVM_GIT_REPO_URL $NVM_DIRECTORY" \
        "Install NVM"

    if [ $? -eq 0 ]; then
        add_nvm_configs
    fi
}

update_nvm() {
    execute "cd $NVM_DIRECTORY && git fetch --quiet origin && git checkout --quiet \$(git describe --abbrev=0 --tags)" \
        "Update NVM"
}

install_global_npm_packages() {
    print_in_purple "\n   Installing global NPM packages\n\n"

    # Load NVM
    . "$NVM_DIRECTORY/nvm.sh"

    # Common global packages
    local packages=(
        "npm@latest"
        "yarn"
        "pm2"
        "nodemon"
        "typescript"
        "ts-node"
        "eslint"
        "prettier"
    )

    for package in "${packages[@]}"; do
        execute "npm install -g $package" "Install $package"
    done
}

main() {
    print_in_purple "\n   Node Version Manager\n\n"

    # Check if NVM is already installed
    if [ ! -d "$NVM_DIRECTORY" ]; then
        install_nvm
    else
        print_success "NVM already installed"
        update_nvm
    fi

    # Install Node.js
    install_latest_stable_node

    # Install global NPM packages
    install_global_npm_packages

    print_in_purple "\n   Node.js Setup Complete\n\n"

    # Show installed versions
    if [ -f "$NVM_DIRECTORY/nvm.sh" ]; then
        . "$NVM_DIRECTORY/nvm.sh"
        echo "   Node version: $(node --version 2>/dev/null || echo 'Not installed')"
        echo "   NPM version: $(npm --version 2>/dev/null || echo 'Not installed')"
        echo ""
    fi
}

main "$@"