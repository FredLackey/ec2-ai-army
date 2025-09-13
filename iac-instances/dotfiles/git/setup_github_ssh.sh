#!/bin/bash

# GitHub SSH Key Setup Script
# This script helps set up SSH keys for GitHub authentication

cd "$(dirname "${BASH_SOURCE[0]}")" \
    && . "../utils.sh"

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

generate_ssh_key() {
    local email="$1"
    local key_file="$HOME/.ssh/id_ed25519"

    # Check if SSH key already exists
    if [ -f "$key_file" ]; then
        ask_for_confirmation "SSH key already exists at $key_file. Generate a new one?"
        if ! answer_is_yes; then
            print_success "Using existing SSH key"
            return 0
        fi

        # Backup existing key
        local backup_file="${key_file}.backup.$(date +%Y%m%d_%H%M%S)"
        execute "mv $key_file $backup_file" "Backup existing private key"
        execute "mv ${key_file}.pub ${backup_file}.pub" "Backup existing public key"
    fi

    # Generate new SSH key
    execute "ssh-keygen -t ed25519 -C \"$email\" -f \"$key_file\" -N \"\"" \
        "Generate SSH key"
}

start_ssh_agent() {
    # Check if ssh-agent is running
    if ! pgrep -x ssh-agent > /dev/null; then
        execute "eval \"\$(ssh-agent -s)\"" "Start SSH agent"
    else
        print_success "SSH agent already running"
    fi

    # Add SSH key to ssh-agent
    local key_file="$HOME/.ssh/id_ed25519"
    if [ -f "$key_file" ]; then
        execute "ssh-add $key_file" "Add SSH key to agent"
    fi
}

configure_ssh_config() {
    local ssh_config="$HOME/.ssh/config"
    local github_config="Host github.com
    HostName github.com
    User git
    IdentityFile ~/.ssh/id_ed25519
    AddKeysToAgent yes"

    # Create .ssh directory if it doesn't exist
    if [ ! -d "$HOME/.ssh" ]; then
        execute "mkdir -p $HOME/.ssh && chmod 700 $HOME/.ssh" "Create SSH directory"
    fi

    # Check if GitHub configuration already exists
    if [ -f "$ssh_config" ]; then
        if grep -q "Host github.com" "$ssh_config" 2>/dev/null; then
            print_success "GitHub SSH config already exists"
            return 0
        fi
    fi

    # Add GitHub configuration
    printf "\n%s\n" "$github_config" >> "$ssh_config"
    print_success "Added GitHub SSH configuration"
}

display_public_key() {
    local key_file="$HOME/.ssh/id_ed25519.pub"

    if [ -f "$key_file" ]; then
        print_in_purple "\n • Public SSH Key (add this to GitHub)\n\n"
        cat "$key_file"
        echo

        # Copy to clipboard if possible
        if cmd_exists "xclip"; then
            cat "$key_file" | xclip -selection clipboard
            print_success "Public key copied to clipboard"
        elif cmd_exists "pbcopy"; then
            cat "$key_file" | pbcopy
            print_success "Public key copied to clipboard"
        else
            print_warning "Install xclip to automatically copy to clipboard"
        fi

        print_in_purple "\n • Next Steps:\n\n"
        echo "  1. Go to https://github.com/settings/keys"
        echo "  2. Click 'New SSH key'"
        echo "  3. Paste the key shown above"
        echo "  4. Give it a descriptive title (e.g., 'EC2 Instance - $(hostname)')"
        echo "  5. Click 'Add SSH key'"
        echo

        ask_for_confirmation "Have you added the key to GitHub?"
        if answer_is_yes; then
            test_github_connection
        else
            print_warning "Remember to add the key to GitHub before pushing code"
        fi
    else
        print_error "SSH key not found at $key_file"
        return 1
    fi
}

test_github_connection() {
    print_in_purple "\n • Testing GitHub SSH connection\n\n"

    # Test SSH connection to GitHub
    ssh -T git@github.com 2>&1 | while IFS= read -r line; do
        if [[ "$line" == *"successfully authenticated"* ]]; then
            print_success "GitHub SSH authentication successful!"
        else
            echo "   $line"
        fi
    done

    return 0
}

setup_git_config() {
    local name=""
    local email=""

    print_in_purple "\n • Git Configuration\n\n"

    # Check if git user.name is set
    if git config --global user.name > /dev/null 2>&1; then
        name=$(git config --global user.name)
        print_success "Git user.name: $name"
    else
        ask "What is your full name for Git commits? "
        name="$(get_answer)"
        execute "git config --global user.name \"$name\"" "Set Git user.name"
    fi

    # Check if git user.email is set
    if git config --global user.email > /dev/null 2>&1; then
        email=$(git config --global user.email)
        print_success "Git user.email: $email"
    else
        ask "What is your email for Git commits? "
        email="$(get_answer)"
        execute "git config --global user.email \"$email\"" "Set Git user.email"
    fi

    return 0
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

main() {
    print_in_purple "\n • GitHub SSH Setup\n\n"

    # Get email for SSH key
    local email=""
    if git config --global user.email > /dev/null 2>&1; then
        email=$(git config --global user.email)
    else
        ask "Enter your GitHub email address: "
        email="$(get_answer)"
    fi

    # Setup Git configuration
    setup_git_config

    # Generate SSH key
    generate_ssh_key "$email"

    # Configure SSH
    configure_ssh_config

    # Start SSH agent and add key
    start_ssh_agent

    # Display public key for user to add to GitHub
    display_public_key

    print_in_purple "\n • GitHub SSH setup complete!\n\n"
}

main "$@"