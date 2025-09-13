# IAC-Instances Dotfiles TODO

This document tracks the missing components and configurations that need to be ported from the global `assets/dotfiles` project to properly provision and configure Ubuntu Server 22 and Ubuntu Server 24 instances.

## IMPORTANT SCOPE CLARIFICATION
These servers are **strictly for terminal-based software development**. They are NOT hosting servers.

### CRITICAL REQUIREMENT: IDEMPOTENCY
**ALL scripts MUST be idempotent** - they must be safe to run multiple times without causing errors or unintended side effects. This is essential for:
- Testing and debugging during development
- Re-running after partial failures
- Updating existing systems
- Ensuring consistent state

#### Idempotency Requirements:
- Check if packages are already installed before installing
- Check if files exist before creating them
- Check if configurations are already applied before applying
- Use conditional logic to skip completed steps
- Provide clear feedback about what was skipped vs. what was executed
- Never fail if the desired state already exists

### Explicitly EXCLUDED Items (Do Not Implement):
- Web browsers (Chrome, Firefox, etc.)
- Image tools (GIMP, ImageMagick, etc.)
- Visual Studio Code configurations
- Security hosting tools (Fail2ban, UFW firewall, RKHunter)
- GUI/Desktop applications
- Compression tools for web serving (Brotli, Zopfli)
- Nginx templates (not needed for dev servers)

## Critical Missing Components

### 1. Shell Configuration Files
- [x] Port all shell configuration files from `assets/dotfiles/src/shell/`
  - [x] `bash_aliases` (main + ubuntu-specific versions)
  - [x] `bash_autocompletion`
  - [x] `bash_exports`
  - [x] `bash_functions` (50KB of functions!)
  - [x] `bash_init`
  - [x] `bash_logout`
  - [x] `bash_options`
  - [x] `bash_profile`
  - [x] `bash_prompt`
  - [x] `bashrc`
  - [x] `bash_colors` (ubuntu-specific)
  - [x] `curlrc`
  - [x] `inputrc`

### 2. Symbolic Links Creation
- [x] Implement `create_symbolic_links.sh` logic
- [x] Create backup mechanism for existing bash files
- [x] Link all configuration files to home directory

### 3. Git Configuration
- [x] Port complete git configuration from `assets/dotfiles/src/git/`
  - [x] `gitattributes`
  - [x] `gitconfig` (full configuration with aliases)
  - [x] `gitignore`
- [x] Implement GitHub SSH key setup script

### 4. Vim Configuration
- [x] Port complete vim setup from `assets/dotfiles/src/vim/`
  - [x] Full `vimrc` file (24KB configuration)
  - [x] Vim directory structure with plugins
  - [x] Snippets configuration (emmet.json)
  - [x] Rainbow levels plugin

### 5. Tmux Configuration
- [x] Port complete tmux configuration from `assets/dotfiles/src/tmux/`
  - [x] Full `tmux.conf` with all keybindings and settings

## Missing Installation Scripts

### 6. Core Installations
- [x] `git.sh` - Git installation and configuration
- [x] `tmux.sh` - Tmux installation
- [x] `vim.sh` - Vim installation with plugins
- [x] `npm.sh` - NPM global packages installation
- [x] `cleanup.sh` - System cleanup after installations

### 7. Additional Tools (from misc.sh)
- [x] Debian Archive Keyring
- [x] CA Certificates (already in docker.sh but needs main install)
- [x] Curl (already in docker.sh but needs main install)
- [x] Software Properties Common
- [x] GNU Privacy Guard

### 8. Development Tools (from misc_tools.sh)
- [x] ShellCheck - Shell script linter
- [x] Tree - Directory tree viewer
- [x] Yarn - Package manager (optional)

## Missing System Preferences

### 9. Ubuntu Preferences
- [x] Port preference scripts from `assets/dotfiles/src/os/preferences/ubuntu-XX-svr/`
  - [x] `main.sh` - Main preferences orchestrator
  - [x] `privacy.sh` - Privacy settings
  - [x] `terminal.sh` - Terminal preferences
  - [x] `ui_and_ux.sh` - UI/UX settings

## Infrastructure Components

### 10. Main Setup Orchestration
- [x] Update main `setup.sh` to follow `assets/dotfiles/src/os/setup.sh` pattern
- [x] Implement proper installation order
- [x] Add OS detection logic (Ubuntu 22 vs 24)
- [x] Add update/upgrade logic

### 11. Utility Functions
- [x] Port missing utility functions from `assets/dotfiles/src/os/utils.sh`
  - [x] `is_git_repository`
  - [x] `get_os`
  - [x] `get_os_version`
  - [x] Color output functions (if missing)
  - [x] Confirmation/question functions

### 12. Directory Structure
- [x] Create proper directory structure matching assets/dotfiles:
  ```
  iac-instances/dotfiles/
  ├── shell/            ✅ (created - contains all shell configs)
  │   ├── ubuntu-22-svr/  ✅ (created with OS-specific configs)
  │   └── ubuntu-24-svr/  ✅ (created with OS-specific configs)
  ├── git/              ✅ (created - contains gitconfig, gitignore, gitattributes, setup_github_ssh.sh)
  ├── vim/              ✅ (created - contains vimrc and vim directory with plugins)
  ├── tmux/             ✅ (created - contains tmux.conf)
  ├── installs/        ✅ (enhanced with new scripts)
  │   ├── git.sh
  │   ├── tmux.sh
  │   ├── vim.sh
  │   ├── npm.sh
  │   ├── misc.sh
  │   ├── misc_tools.sh
  │   └── cleanup.sh
  └── preferences/      ✅ (created with Ubuntu version support)
      ├── main.sh
      ├── ubuntu-22-svr/
      │   ├── privacy.sh
      │   ├── terminal.sh
      │   └── ui_and_ux.sh
      └── ubuntu-24-svr/
          ├── privacy.sh
          ├── terminal.sh
          └── ui_and_ux.sh
  ```

## Development Environment Configuration

### 13. SSH Configuration
- [x] Implement SSH key generation for Git operations
- [x] GitHub SSH key setup
- [ ] SSH config file management

### 14. Documentation
- [ ] Markdown lint configuration (`.markdownlint.json`) - for development purposes only

## Already Implemented (Verify Completeness)

### Existing Components to Review:
- [x] Docker installation (docker.sh) - Review against assets version
- [x] NVM installation (nvm.sh) - Review against assets version
- [x] Build essentials (build_essentials.sh) - Compare with assets version
- [x] Basic utilities (utilities.sh) - Has more tools than assets version
- [x] Basic bash configs - Need to verify against assets versions

## Priority Order

1. **Phase 1 - Core Shell Environment** ✅ COMPLETED
   - [x] Shell configuration files
   - [x] Symbolic links creation
   - [x] Basic utility functions

2. **Phase 2 - Development Tools** ✅ COMPLETED
   - [x] Git configuration
   - [x] Vim setup
   - [x] Tmux configuration

3. **Phase 3 - System Tools** ✅ COMPLETED
   - [x] Missing installation scripts
   - [x] System preferences
   - [x] Directory restructuring

4. **Phase 4 - Development Environment**
   - SSH configuration for Git operations
   - Development-specific configurations

## Notes

- The global `assets/dotfiles` supports multiple Ubuntu versions (20, 22, 23, 24) and both server/workstation variants
- Current `iac-instances/dotfiles` appears to be a simplified version missing many critical components
- This setup is specifically for **terminal-based development servers only**
- No GUI applications, browsers, or hosting-related security tools are needed

## Next Steps

1. Start with Phase 1 to establish proper shell environment
2. **Ensure all scripts are idempotent before moving to next phase**
3. Test each component on both Ubuntu 22 and 24 servers
4. Re-run scripts multiple times to verify idempotency
5. Create version-specific configurations where needed
6. Document any EC2-specific modifications or exclusions

## Implementation Guidelines

When implementing these items, follow these patterns for idempotency:

### For Package Installation:
```bash
if ! package_is_installed "package-name"; then
    install_package "Package Description" "package-name"
else
    print_success "Package already installed"
fi
```

### For File Creation:
```bash
if [ ! -f "$file_path" ]; then
    # Create file
    print_success "Created $file_path"
else
    print_success "$file_path already exists"
fi
```

### For Configuration Changes:
```bash
if ! grep -q "config_line" "$config_file"; then
    echo "config_line" >> "$config_file"
    print_success "Configuration added"
else
    print_success "Configuration already present"
fi
```