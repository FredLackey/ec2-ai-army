#!/bin/bash

cd "$(dirname "${BASH_SOURCE[0]}")" \
    && . "../../utils.sh"

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

configure_motd() {
    print_in_purple "\n   MOTD Configuration\n\n"

    # Disable unnecessary MOTD scripts
    local motd_files=(
        "10-help-text"
        "50-motd-news"
        "80-esm"
        "95-hwe-eol"
    )

    for file in "${motd_files[@]}"; do
        if [ -f "/etc/update-motd.d/$file" ]; then
            execute "sudo chmod -x /etc/update-motd.d/$file" \
                "Disable $file MOTD script"
        fi
    done

    # Create custom MOTD
    local custom_motd="/etc/update-motd.d/01-custom"
    if [ ! -f "$custom_motd" ]; then
        sudo tee "$custom_motd" > /dev/null << 'EOF'
#!/bin/bash

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Get system information
HOSTNAME=$(hostname)
KERNEL=$(uname -r)
UPTIME=$(uptime -p | sed 's/up //')
LOAD=$(cat /proc/loadavg | awk '{print $1, $2, $3}')
MEM_USED=$(free -h | awk 'NR==2{printf "%.1f/%.1fGB (%.1f%%)", $3, $2, $3*100/$2}')
DISK_USED=$(df -h / | awk 'NR==2{printf "%s/%s (%s)", $3, $2, $5}')
IP=$(hostname -I | awk '{print $1}')
PROCS=$(ps aux | wc -l)

echo
echo -e "${CYAN}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║${NC}  ${GREEN}Welcome to ${HOSTNAME}${NC}"
echo -e "${CYAN}╠═══════════════════════════════════════════════════════════╣${NC}"
echo -e "${CYAN}║${NC}  ${YELLOW}System Information:${NC}"
echo -e "${CYAN}║${NC}    Kernel:   ${KERNEL}"
echo -e "${CYAN}║${NC}    Uptime:   ${UPTIME}"
echo -e "${CYAN}║${NC}    Load:     ${LOAD}"
echo -e "${CYAN}║${NC}    Memory:   ${MEM_USED}"
echo -e "${CYAN}║${NC}    Disk:     ${DISK_USED}"
echo -e "${CYAN}║${NC}    IP:       ${IP}"
echo -e "${CYAN}║${NC}    Procs:    ${PROCS}"
echo -e "${CYAN}╚═══════════════════════════════════════════════════════════╝${NC}"
echo
EOF
        sudo chmod +x "$custom_motd"
        print_success "Created custom MOTD"
    else
        print_success "Custom MOTD already exists"
    fi
}

configure_aliases() {
    print_in_purple "\n   System Aliases\n\n"

    # Add useful aliases if not already present
    local aliases_file="$HOME/.bash_aliases"

    # Check if aliases file is already linked
    if [ -L "$aliases_file" ]; then
        print_success "Aliases already configured via symlink"
        return 0
    fi

    # If not linked, add some basic aliases
    if [ -f "$aliases_file" ]; then
        print_success "Aliases file already exists"
    else
        cat > "$aliases_file" << 'EOF'
# System aliases (backup - should be replaced by symlink)

# Navigation
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias ~='cd ~'

# List
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

# Safety
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'

# Shortcuts
alias g='git'
alias v='vim'
alias t='tmux'
alias h='history'
alias j='jobs'

# System
alias update='sudo apt update && sudo apt upgrade'
alias install='sudo apt install'
alias search='apt search'
alias ports='netstat -tuln'
alias myip='curl -s https://api.ipify.org && echo'

# Docker (if installed)
alias d='docker'
alias dc='docker-compose'
alias dps='docker ps'
alias dpa='docker ps -a'
alias di='docker images'

# Python
alias py='python3'
alias pip='pip3'
alias venv='python3 -m venv'
alias activate='source venv/bin/activate'

# Process
alias psg='ps aux | grep -v grep | grep'
alias meminfo='free -h'
alias cpuinfo='lscpu'
alias diskinfo='df -h'

# Tmux
alias ta='tmux attach -t'
alias tl='tmux list-sessions'
alias tn='tmux new-session -s'
alias tk='tmux kill-session -t'
EOF
        print_success "Created aliases file"
    fi
}

configure_user_experience() {
    print_in_purple "\n   User Experience Settings\n\n"

    # Enable color support for ls
    if [ -f "$HOME/.bashrc" ]; then
        if ! grep -q "alias ls='ls --color=auto'" "$HOME/.bashrc" 2>/dev/null; then
            cat >> "$HOME/.bashrc" << 'EOF'

# Enable color support
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi
EOF
            print_success "Enable color support"
        else
            print_success "Color support already enabled"
        fi
    fi

    # Configure less pager
    if ! grep -q "LESS=" "$HOME/.bashrc" 2>/dev/null; then
        cat >> "$HOME/.bashrc" << 'EOF'

# Less pager configuration
export LESS='-R -F -X -i -P ?f%f:stdin. ?m(%i/%m) .?lt%lt-%lb?L/%L. :byte %bB?s/%s. .?e(END) :?pB%pB\%..%t'
export LESSCHARSET='utf-8'
EOF
        print_success "Configure less pager"
    else
        print_success "Less pager already configured"
    fi

    # Enable useful bash options
    local bash_options=(
        "shopt -s cdspell"        # Correct minor cd spelling errors
        "shopt -s checkwinsize"   # Update LINES and COLUMNS after each command
        "shopt -s cmdhist"        # Save multi-line commands as one command
        "shopt -s dotglob"        # Include dotfiles in globbing
        "shopt -s expand_aliases" # Expand aliases
        "shopt -s extglob"        # Extended globbing
        "shopt -s nocaseglob"     # Case-insensitive globbing
    )

    for option in "${bash_options[@]}"; do
        if ! grep -q "$option" "$HOME/.bashrc" 2>/dev/null; then
            echo "$option" >> "$HOME/.bashrc"
            print_success "Enable: $option"
        fi
    done
}

configure_sudo() {
    print_in_purple "\n   Sudo Configuration\n\n"

    # Add timestamp_timeout to sudoers (extends sudo timeout)
    local sudoers_file="/etc/sudoers.d/99-timeout"
    if [ ! -f "$sudoers_file" ]; then
        echo "Defaults timestamp_timeout=30" | sudo tee "$sudoers_file" > /dev/null
        print_success "Set sudo timeout to 30 minutes"
    else
        print_success "Sudo timeout already configured"
    fi

    # Enable sudo insults (fun feature)
    ask_for_confirmation "Enable sudo insults (fun messages on wrong password)?"
    if answer_is_yes; then
        local insults_file="/etc/sudoers.d/99-insults"
        if [ ! -f "$insults_file" ]; then
            echo "Defaults insults" | sudo tee "$insults_file" > /dev/null
            print_success "Enable sudo insults"
        else
            print_success "Sudo insults already enabled"
        fi
    fi
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

main() {
    configure_motd
    configure_aliases
    configure_user_experience
    configure_sudo
}

main "$@"