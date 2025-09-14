#!/bin/bash

cd "$(dirname "${BASH_SOURCE[0]}")" && . "../utils.sh"

install_grok_cli() {
    print_in_purple "\n   Grok CLI AI Assistant\n\n"

    # Install Grok CLI via npm
    if npm list -g "@vibe-kit/grok-cli" &>/dev/null; then
        print_success "@vibe-kit/grok-cli (already installed)"
    else
        execute "npm install -g @vibe-kit/grok-cli" "@vibe-kit/grok-cli"
    fi

    # Verify installation
    if cmd_exists "grok"; then
        print_success "Grok CLI installation verified"
        execute "grok --version" "Grok CLI version"
    else
        print_error "Grok CLI installation failed"
        return 1
    fi
}

main() {
    print_in_purple "\n • Grok CLI Setup\n\n"

    # Check if npm is available
    if ! cmd_exists "npm"; then
        print_error "NPM is not installed. Please install Node.js first (run nvm.sh)"
        return 1
    fi

    install_grok_cli

    print_in_purple "\n   Grok CLI setup complete!\n"
    print_in_yellow "   Run 'grok' in any project directory to start\n"
    print_in_yellow "   Note: Configure GROK_API_KEY environment variable for authentication\n"
}

main "$@"
