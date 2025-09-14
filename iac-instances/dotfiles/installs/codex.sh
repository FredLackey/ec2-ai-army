#!/bin/bash

cd "$(dirname "${BASH_SOURCE[0]}")" && . "../utils.sh"

install_codex_cli() {
    print_in_purple "\n   Codex CLI AI Assistant\n\n"

    # Install Codex CLI via npm
    if npm list -g "@openai/codex" &>/dev/null; then
        print_success "@openai/codex (already installed)"
    else
        execute "npm install -g @openai/codex" "@openai/codex"
    fi

    # Verify installation
    if cmd_exists "codex"; then
        print_success "Codex CLI installation verified"
        execute "codex --version" "Codex CLI version"
    else
        print_error "Codex CLI installation failed"
        return 1
    fi
}

main() {
    print_in_purple "\n • Codex CLI Setup\n\n"

    # Check if npm is available
    if ! cmd_exists "npm"; then
        print_error "NPM is not installed. Please install Node.js first (run nvm.sh)"
        return 1
    fi

    install_codex_cli

    print_in_purple "\n   Codex CLI setup complete!\n"
    print_in_yellow "   Run 'codex' in any project directory to start\n"
}

main "$@"
