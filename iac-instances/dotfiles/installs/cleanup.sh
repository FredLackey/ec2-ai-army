#!/bin/bash

cd "$(dirname "${BASH_SOURCE[0]}")" \
    && . "../utils.sh"

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

clean_apt_cache() {
    print_in_purple "\n   APT Cache Cleanup\n\n"

    # Clean package cache
    execute "sudo apt-get clean" \
        "Clean package cache"

    # Remove partial packages
    execute "sudo apt-get autoclean" \
        "Remove partial packages"

    # Get size of APT cache before and after
    local cache_dir="/var/cache/apt/archives"
    if [ -d "$cache_dir" ]; then
        local cache_size=$(du -sh "$cache_dir" 2>/dev/null | cut -f1)
        print_success "APT cache cleaned (freed: ~$cache_size)"
    fi
}

remove_orphaned_packages() {
    print_in_purple "\n   Remove Orphaned Packages\n\n"

    # Remove automatically installed packages that are no longer needed
    execute "sudo apt-get autoremove -y" \
        "Remove orphaned packages"

    # Remove orphaned packages with deborphan if available
    if cmd_exists "deborphan"; then
        local orphans=$(deborphan)
        if [ -n "$orphans" ]; then
            execute "sudo deborphan | xargs sudo apt-get -y remove --purge" \
                "Remove orphaned libraries"
        else
            print_success "No orphaned libraries found"
        fi
    else
        # Optionally install deborphan
        ask_for_confirmation "Install deborphan to find orphaned packages?"
        if answer_is_yes; then
            install_package "Deborphan" "deborphan"
            remove_orphaned_packages
        fi
    fi
}

clean_old_kernels() {
    print_in_purple "\n   Old Kernel Cleanup\n\n"

    # Get current kernel version
    local current_kernel=$(uname -r)
    print_success "Current kernel: $current_kernel"

    # Find old kernels (keep current and one previous)
    local old_kernels=$(dpkg -l 'linux-*' | sed '/^ii/!d;/'"$(uname -r | sed "s/\(.*\)-\([^0-9]\+\)/\1/")"'/d;s/^[^ ]* [^ ]* \([^ ]*\).*/\1/;/[0-9]/!d' | head -n -1)

    if [ -n "$old_kernels" ]; then
        ask_for_confirmation "Remove old kernel packages?"
        if answer_is_yes; then
            for kernel in $old_kernels; do
                execute "sudo apt-get -y purge $kernel" "Remove $kernel"
            done
        else
            print_warning "Skipping old kernel removal"
        fi
    else
        print_success "No old kernels to remove"
    fi
}

clean_temp_files() {
    print_in_purple "\n   Temporary Files Cleanup\n\n"

    # Clean /tmp (files older than 7 days)
    if [ -d "/tmp" ]; then
        execute "find /tmp -type f -atime +7 -delete 2>/dev/null || true" \
            "Clean old files in /tmp"
    fi

    # Clean user temp files
    if [ -d "$HOME/.cache" ]; then
        local cache_size=$(du -sh "$HOME/.cache" 2>/dev/null | cut -f1)
        ask_for_confirmation "Clear user cache (~$cache_size)?"
        if answer_is_yes; then
            execute "rm -rf $HOME/.cache/*" "Clear user cache"
        fi
    fi

    # Clean thumbnail cache
    if [ -d "$HOME/.thumbnails" ]; then
        execute "rm -rf $HOME/.thumbnails/*" "Clear thumbnail cache"
    fi

    # Clean trash
    if [ -d "$HOME/.local/share/Trash" ]; then
        local trash_size=$(du -sh "$HOME/.local/share/Trash" 2>/dev/null | cut -f1)
        if [ "$trash_size" != "0" ]; then
            ask_for_confirmation "Empty trash (~$trash_size)?"
            if answer_is_yes; then
                execute "rm -rf $HOME/.local/share/Trash/*" "Empty trash"
            fi
        else
            print_success "Trash is already empty"
        fi
    fi
}

clean_log_files() {
    print_in_purple "\n   Log Files Cleanup\n\n"

    # Rotate and compress logs
    if cmd_exists "logrotate"; then
        execute "sudo logrotate -f /etc/logrotate.conf" \
            "Rotate system logs"
    fi

    # Clean old compressed logs (older than 30 days)
    execute "sudo find /var/log -type f -name '*.gz' -mtime +30 -delete 2>/dev/null || true" \
        "Remove old compressed logs"

    # Clean journal logs (keep last 2 weeks)
    if cmd_exists "journalctl"; then
        execute "sudo journalctl --vacuum-time=2weeks" \
            "Clean systemd journal logs"
    fi
}

clean_docker_resources() {
    print_in_purple "\n   Docker Cleanup\n\n"

    if cmd_exists "docker"; then
        # Check if Docker daemon is running
        if docker info &>/dev/null; then
            # Remove stopped containers
            local stopped_containers=$(docker ps -aq -f status=exited 2>/dev/null)
            if [ -n "$stopped_containers" ]; then
                execute "docker rm $stopped_containers" \
                    "Remove stopped containers"
            else
                print_success "No stopped containers to remove"
            fi

            # Remove dangling images
            local dangling_images=$(docker images -qf dangling=true 2>/dev/null)
            if [ -n "$dangling_images" ]; then
                execute "docker rmi $dangling_images" \
                    "Remove dangling images"
            else
                print_success "No dangling images to remove"
            fi

            # Remove unused volumes
            execute "docker volume prune -f" \
                "Remove unused volumes"

            # Remove unused networks
            execute "docker network prune -f" \
                "Remove unused networks"

            # Full system prune (optional)
            ask_for_confirmation "Perform full Docker system prune?"
            if answer_is_yes; then
                execute "docker system prune -af --volumes" \
                    "Full Docker system cleanup"
            fi
        else
            print_warning "Docker daemon is not running"
        fi
    else
        print_success "Docker not installed (skipping)"
    fi
}

clean_npm_cache() {
    print_in_purple "\n   NPM Cache Cleanup\n\n"

    if cmd_exists "npm"; then
        execute "npm cache clean --force" \
            "Clean NPM cache"
    else
        print_success "NPM not installed (skipping)"
    fi
}

clean_pip_cache() {
    print_in_purple "\n   pip Cache Cleanup\n\n"

    if cmd_exists "pip3"; then
        execute "pip3 cache purge" \
            "Clean pip cache"
    else
        print_success "pip not installed (skipping)"
    fi
}

update_locate_database() {
    print_in_purple "\n   Update Locate Database\n\n"

    if cmd_exists "updatedb"; then
        execute "sudo updatedb" \
            "Update locate database"
    else
        install_package "mlocate" "mlocate"
        execute "sudo updatedb" \
            "Update locate database"
    fi
}

show_disk_usage() {
    print_in_purple "\n   Disk Usage Summary\n\n"

    # Show filesystem usage
    df -h | grep -E '^/dev/' | while IFS= read -r line; do
        echo "   $line"
    done

    echo

    # Show top 10 largest directories in home
    if cmd_exists "du"; then
        print_in_purple "   Largest directories in $HOME:\n"
        du -sh $HOME/* 2>/dev/null | sort -rh | head -10 | while IFS= read -r line; do
            echo "   $line"
        done
    fi
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

main() {
    print_in_purple "\n • System Cleanup\n\n"

    ask_for_sudo

    # Perform cleanup operations
    clean_apt_cache
    remove_orphaned_packages
    clean_old_kernels
    clean_temp_files
    clean_log_files
    clean_docker_resources
    clean_npm_cache
    clean_pip_cache

    # Update system databases
    update_locate_database

    # Show disk usage summary
    show_disk_usage

    print_in_purple "\n   System cleanup complete!\n"
}

main "$@"