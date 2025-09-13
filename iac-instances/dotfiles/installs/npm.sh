#!/bin/bash

cd "$(dirname "${BASH_SOURCE[0]}")" \
    && . "../utils.sh"

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

declare -a NPM_PACKAGES=(
    # Package managers and build tools
    "yarn"
    "pnpm"

    # Linters and formatters
    "eslint"
    "prettier"
    "stylelint"

    # Development tools
    "nodemon"
    "concurrently"
    "cross-env"
    "dotenv-cli"
    "rimraf"

    # Testing tools
    "jest"
    "mocha"

    # TypeScript
    "typescript"
    "ts-node"
    "tsx"

    # HTTP and API tools
    "http-server"
    "json-server"
    "serve"

    # CLI tools
    "npm-check-updates"
    "npkill"
    "npm-check"

    # Documentation
    "jsdoc"
    "typedoc"

    # Git hooks
    "husky"
    "lint-staged"
    "commitizen"
    "cz-conventional-changelog"
)

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

install_npm_package() {
    local package="$1"

    # Check if package is already installed globally
    if npm list -g "$package" &>/dev/null; then
        print_success "$package (already installed)"
    else
        execute "npm install -g $package" "$package"
    fi
}

configure_npm() {
    print_in_purple "\n   NPM Configuration\n\n"

    # Set npm init defaults
    execute "npm config set init-author-name \"$(git config --global user.name 2>/dev/null || echo '')\"" \
        "Set npm author name"

    execute "npm config set init-author-email \"$(git config --global user.email 2>/dev/null || echo '')\"" \
        "Set npm author email"

    execute "npm config set init-license MIT" \
        "Set default license to MIT"

    # Enable npm completion
    if [ -f "$HOME/.bashrc" ]; then
        if ! grep -q "npm completion" "$HOME/.bashrc" 2>/dev/null; then
            execute "npm completion >> $HOME/.bashrc" \
                "Add npm completion to bashrc"
        else
            print_success "npm completion already configured"
        fi
    fi

    # Create npmrc for additional configurations
    local NPMRC="$HOME/.npmrc"
    if [ ! -f "$NPMRC" ]; then
        cat > "$NPMRC" << 'EOF'
# NPM Configuration

# Save exact versions
save-exact=false

# Use lockfiles
package-lock=true

# Progress bar
progress=true

# Audit level
audit-level=moderate

# Fund
fund=false

# Update notifier
update-notifier=true
EOF
        print_success "Created .npmrc configuration"
    else
        print_success ".npmrc already exists"
    fi
}

update_npm() {
    print_in_purple "\n   Update NPM\n\n"

    # Update npm itself to latest version
    if cmd_exists "npm"; then
        local current_version=$(npm --version)
        execute "npm install -g npm@latest" "Update npm to latest version"
        local new_version=$(npm --version)

        if [ "$current_version" != "$new_version" ]; then
            print_success "NPM updated from $current_version to $new_version"
        else
            print_success "NPM already at latest version ($current_version)"
        fi
    fi
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

main() {
    print_in_purple "\n • NPM Global Packages\n\n"

    # Check if npm is available
    if ! cmd_exists "npm"; then
        print_error "NPM is not installed. Please install Node.js first (run nvm.sh)"
        return 1
    fi

    # Update npm first
    update_npm

    # Configure npm
    configure_npm

    # Install global packages
    print_in_purple "\n   Installing NPM packages\n\n"

    for package in "${NPM_PACKAGES[@]}"; do
        install_npm_package "$package"
    done

    # Clean npm cache
    execute "npm cache clean --force" "Clean NPM cache"

    print_in_purple "\n   NPM packages installation complete!\n"
}

main "$@"