#!/bin/bash

cd "$(dirname "${BASH_SOURCE[0]}")" && . "../utils.sh"

remove_old_docker() {
    print_in_purple "\n   Removing old Docker packages\n\n"

    local old_packages=(
        "docker"
        "docker-engine"
        "docker.io"
        "containerd"
        "runc"
        "docker-compose"
    )

    for package in "${packages[@]}"; do
        if package_is_installed "$package"; then
            execute "sudo apt-get remove -y $package" "Remove $package"
        fi
    done
}

install_docker_prerequisites() {
    print_in_purple "\n   Installing Docker prerequisites\n\n"

    install_package "CA Certificates" "ca-certificates"
    install_package "Curl" "curl"
    install_package "GnuPG" "gnupg"
    install_package "LSB Release" "lsb-release"
}

add_docker_repository() {
    print_in_purple "\n   Adding Docker repository\n\n"

    # Add Docker's official GPG key
    execute "sudo mkdir -p /etc/apt/keyrings" "Create keyrings directory"

    execute "curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg" \
        "Add Docker GPG key"

    # Set up the repository
    execute "echo \"deb [arch=\$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \$(lsb_release -cs) stable\" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null" \
        "Add Docker repository"

    # Update package index
    execute "sudo apt-get update -y" "Update package index"
}

install_docker_engine() {
    print_in_purple "\n   Installing Docker Engine\n\n"

    install_package "Docker CE" "docker-ce"
    install_package "Docker CE CLI" "docker-ce-cli"
    install_package "Containerd.io" "containerd.io"
    install_package "Docker Buildx Plugin" "docker-buildx-plugin"
    install_package "Docker Compose Plugin" "docker-compose-plugin"
}

configure_docker() {
    print_in_purple "\n   Configuring Docker\n\n"

    # Add current user to docker group
    execute "sudo usermod -aG docker $USER" \
        "Add $USER to docker group"

    # Create docker config directory
    execute "mkdir -p $HOME/.docker" \
        "Create Docker config directory"

    # Enable and start Docker service
    execute "sudo systemctl enable docker" \
        "Enable Docker service"

    execute "sudo systemctl start docker" \
        "Start Docker service"

    # Configure Docker daemon with better defaults
    local docker_config='/etc/docker/daemon.json'
    local config_content='{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  },
  "storage-driver": "overlay2"
}'

    if [ ! -f "$docker_config" ]; then
        execute "echo '$config_content' | sudo tee $docker_config > /dev/null" \
            "Configure Docker daemon"

        execute "sudo systemctl restart docker" \
            "Restart Docker service"
    else
        print_success "Docker daemon already configured"
    fi
}

verify_docker_installation() {
    print_in_purple "\n   Verifying Docker installation\n\n"

    # Check Docker version
    if cmd_exists docker; then
        local docker_version=$(docker --version 2>/dev/null)
        print_success "Docker installed: $docker_version"
    else
        print_error "Docker installation failed"
        return 1
    fi

    # Check Docker Compose version
    if docker compose version &>/dev/null; then
        local compose_version=$(docker compose version 2>/dev/null)
        print_success "Docker Compose installed: $compose_version"
    else
        print_warning "Docker Compose not available"
    fi

    print_warning "Note: You need to log out and back in for group changes to take effect"
    print_warning "Or run: newgrp docker"
}

main() {
    print_in_purple "\n   Docker Installation\n\n"

    # Check if Docker is already installed
    if cmd_exists docker; then
        print_success "Docker is already installed"
        docker --version

        ask_for_confirmation "Do you want to reinstall Docker?"
        if ! answer_is_yes; then
            return 0
        fi
        remove_old_docker
    fi

    # Install Docker
    install_docker_prerequisites
    add_docker_repository
    install_docker_engine
    configure_docker
    verify_docker_installation

    print_in_purple "\n   Docker Setup Complete\n\n"
}

main "$@"