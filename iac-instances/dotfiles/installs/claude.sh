#!/bin/bash

cd "$(dirname "${BASH_SOURCE[0]}")" && . "../utils.sh"

install_claude_code() {
    print_in_purple "\n   Claude Code AI Assistant\n\n"

    # Ensure ripgrep is installed (dependency for search functionality)
    install_package "Ripgrep" "ripgrep"

    # Install Claude Code via npm
    if npm list -g "@anthropic-ai/claude-code" &>/dev/null; then
        print_success "@anthropic-ai/claude-code (already installed)"
    else
        execute "npm install -g @anthropic-ai/claude-code" "@anthropic-ai/claude-code"
    fi

    # Verify installation
    if cmd_exists "claude"; then
        print_success "Claude Code installation verified"
        execute "claude --version" "Claude Code version"
    else
        print_error "Claude Code installation failed"
        return 1
    fi
}

main() {
    print_in_purple "\n • Claude Code Setup\n\n"

    # Check if npm is available
    if ! cmd_exists "npm"; then
        print_error "NPM is not installed. Please install Node.js first (run nvm.sh)"
        return 1
    fi

    install_claude_code

    print_in_purple "\n   Claude Code setup complete!\n"
    print_in_yellow "   Run 'claude' in any project directory to start\n"
}

main "$@"
