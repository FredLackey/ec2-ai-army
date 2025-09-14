#!/bin/bash

cd "$(dirname "${BASH_SOURCE[0]}")" && . "../utils.sh"

install_gemini_cli() {
    print_in_purple "\n   Gemini CLI AI Assistant\n\n"

    # Install Gemini CLI via npm
    if npm list -g "@google/gemini-cli" &>/dev/null; then
        print_success "@google/gemini-cli (already installed)"
    else
        execute "npm install -g @google/gemini-cli" "@google/gemini-cli"
    fi

    # Verify installation
    if cmd_exists "gemini"; then
        print_success "Gemini CLI installation verified"
        execute "gemini --version" "Gemini CLI version"
    else
        print_error "Gemini CLI installation failed"
        return 1
    fi
}

main() {
    print_in_purple "\n • Gemini CLI Setup\n\n"

    # Check if npm is available
    if ! cmd_exists "npm"; then
        print_error "NPM is not installed. Please install Node.js first (run nvm.sh)"
        return 1
    fi

    install_gemini_cli

    print_in_purple "\n   Gemini CLI setup complete!\n"
    print_in_yellow "   Run 'gemini' in any project directory to start\n"
}

main "$@"
