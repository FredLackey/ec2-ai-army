#!/bin/bash

cd "$(dirname "${BASH_SOURCE[0]}")" && . "../utils.sh"

install_system_utilities() {
    print_in_purple "\n   System Utilities\n\n"

    # Text editors
    install_package "Vim" "vim"
    install_package "Nano" "nano"

    # Terminal multiplexer
    install_package "Tmux" "tmux"
    install_package "Screen" "screen"

    # System monitoring
    install_package "Htop" "htop"
    install_package "IOTop" "iotop"
    install_package "IFTop" "iftop"
    install_package "NCurses Disk Usage" "ncdu"
    install_package "Net Tools" "net-tools"
    install_package "LSOF" "lsof"
    install_package "Strace" "strace"
    install_package "SysStat" "sysstat"

    # Network utilities
    install_package "Traceroute" "traceroute"
    install_package "MTR" "mtr"
    install_package "IPUtils Ping" "iputils-ping"
    install_package "DNS Utils" "dnsutils"
    install_package "Netcat" "netcat"
    install_package "TCPDump" "tcpdump"
    install_package "NMap" "nmap"
    install_package "WhoIs" "whois"

    # File utilities
    install_package "Tree" "tree"
    install_package "JQ" "jq"
    install_package "YQ" "yq"
    install_package "Ripgrep" "ripgrep"
    install_package "FD Find" "fd-find"
    install_package "The Silver Searcher" "silversearcher-ag"
    install_package "Bat" "bat"
    install_package "FZF" "fzf"

    # Archive utilities
    install_package "P7Zip" "p7zip-full"
    install_package "RAR" "rar"
    install_package "UnRAR" "unrar"

    # Development utilities
    install_package "HTTPie" "httpie"
    install_package "Direnv" "direnv"
    install_package "ASCIInema" "asciinema"

    # Security utilities
    install_package "Fail2ban" "fail2ban"
    install_package "UFW" "ufw"
    install_package "RKHunter" "rkhunter"

    # Cloud CLI tools (AWS)
    if ! cmd_exists aws; then
        execute "curl \"https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip\" -o \"awscliv2.zip\" && unzip -q awscliv2.zip && sudo ./aws/install && rm -rf awscliv2.zip aws/" \
            "AWS CLI v2"
    else
        print_success "AWS CLI (already installed)"
    fi
}

configure_vim() {
    print_in_purple "\n   Configuring Vim\n\n"

    local vimrc="$HOME/.vimrc"
    local vim_config='
" Basic Settings
set nocompatible
set encoding=utf-8
set number
set relativenumber
set cursorline
set showmatch
set autoindent
set smartindent
set expandtab
set tabstop=4
set shiftwidth=4
set softtabstop=4
set ruler
set laststatus=2
set wildmenu
set wildmode=longest:full,full
set ignorecase
set smartcase
set incsearch
set hlsearch
set backspace=indent,eol,start
set clipboard=unnamedplus
set mouse=a
set scrolloff=8
set sidescrolloff=8

" Visual Settings
syntax enable
set background=dark
set termguicolors

" File Settings
set nobackup
set nowritebackup
set noswapfile
set autoread

" Key Mappings
let mapleader = " "
nnoremap <leader>w :w<CR>
nnoremap <leader>q :q<CR>
nnoremap <leader>x :x<CR>
nnoremap <C-h> <C-w>h
nnoremap <C-j> <C-w>j
nnoremap <C-k> <C-w>k
nnoremap <C-l> <C-w>l

" Clear search highlighting
nnoremap <leader>/ :nohlsearch<CR>
'

    if [ ! -f "$vimrc" ]; then
        execute "echo '$vim_config' > $vimrc" "Create Vim configuration"
    else
        print_success "Vim configuration (already exists)"
    fi
}

configure_tmux() {
    print_in_purple "\n   Configuring Tmux\n\n"

    local tmux_conf="$HOME/.tmux.conf"
    local tmux_config='
# Remap prefix from Ctrl-b to Ctrl-a
unbind C-b
set-option -g prefix C-a
bind-key C-a send-prefix

# Split panes using | and -
bind | split-window -h
bind - split-window -v
unbind '"'"'"'
unbind %

# Reload config file
bind r source-file ~/.tmux.conf

# Switch panes using Alt-arrow without prefix
bind -n M-Left select-pane -L
bind -n M-Right select-pane -R
bind -n M-Up select-pane -U
bind -n M-Down select-pane -D

# Enable mouse mode
set -g mouse on

# Start windows and panes at 1, not 0
set -g base-index 1
setw -g pane-base-index 1

# Set default terminal
set -g default-terminal "screen-256color"

# Status bar
set -g status-position bottom
set -g status-style "bg=colour234 fg=colour137"
set -g status-left ""
set -g status-right "#[fg=colour233,bg=colour241,bold] %d/%m #[fg=colour233,bg=colour245,bold] %H:%M:%S "
set -g status-right-length 50
set -g status-left-length 20

# History
set -g history-limit 10000

# Vim mode
setw -g mode-keys vi
'

    if [ ! -f "$tmux_conf" ]; then
        execute "echo '$tmux_config' > $tmux_conf" "Create Tmux configuration"
    else
        print_success "Tmux configuration (already exists)"
    fi
}

configure_git() {
    print_in_purple "\n   Configuring Git\n\n"

    # Set up basic git configuration
    if ! git config --global user.name &>/dev/null; then
        git config --global user.name "AI Army Instance"
        print_success "Git user.name configured"
    else
        print_success "Git user.name (already configured)"
    fi

    if ! git config --global user.email &>/dev/null; then
        git config --global user.email "instance@ai-army.local"
        print_success "Git user.email configured"
    else
        print_success "Git user.email (already configured)"
    fi

    # Set up useful git aliases
    git config --global alias.co checkout
    git config --global alias.br branch
    git config --global alias.ci commit
    git config --global alias.st status
    git config --global alias.unstage 'reset HEAD --'
    git config --global alias.last 'log -1 HEAD'
    git config --global alias.visual '!gitk'
    git config --global alias.lg "log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit"

    # Set default branch name
    git config --global init.defaultBranch main

    # Enable colors
    git config --global color.ui auto

    print_success "Git aliases configured"
}

main() {
    print_in_purple "\n   Development Utilities\n\n"

    install_system_utilities
    configure_vim
    configure_tmux
    configure_git

    print_in_purple "\n   Utilities Setup Complete\n\n"
}

main "$@"