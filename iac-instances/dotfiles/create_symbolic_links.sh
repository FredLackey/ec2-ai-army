#!/bin/bash

cd "$(dirname "${BASH_SOURCE[0]}")" \
    && . "utils.sh"

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

backup_bash_files() {
    local backup_dir="$HOME/.bash_backups"

    # Create backup directory if it doesn't exist
    if [ ! -d "$backup_dir" ]; then
        execute "mkdir -p $backup_dir" "Create backup directory"
    fi

    # Backup existing bash files
    find "$HOME" -maxdepth 1 -name ".bash*" -type f | while IFS= read -r file; do
        local filename=$(basename "$file")
        local backup_file="$backup_dir/${filename}-$(date +%Y%m%d_%H%M%S)"

        # Check if this is already a symlink to our dotfiles
        if [ -L "$file" ] && [[ "$(readlink "$file")" == *"iac-instances/dotfiles"* ]]; then
            print_success "Skipping backup of $filename (already our symlink)"
        else
            if [ -e "$file" ]; then
                execute "cp $file $backup_file" "Backup $filename"
            fi
        fi
    done
}

create_symlinks() {

    declare -a FILES_TO_SYMLINK=(
        "shell/bash_aliases"
        "shell/bash_autocompletion"
        "shell/bash_exports"
        "shell/bash_functions"
        "shell/bash_init"
        "shell/bash_logout"
        "shell/bash_options"
        "shell/bash_profile"
        "shell/bash_prompt"
        "shell/bashrc"
        "shell/curlrc"
        "shell/inputrc"

        "git/gitattributes"
        "git/gitconfig"
        "git/gitignore"

        "tmux/tmux.conf"

        "vim/vim"
        "vim/vimrc"
    )

    local i=""
    local sourceFile=""
    local targetFile=""
    local skipQuestions=false
    local os_version=""

    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    skip_questions "$@" \
        && skipQuestions=true

    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    # Detect Ubuntu version
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        if [[ "$ID" == "ubuntu" ]]; then
            if [[ "$VERSION_ID" == "22.04" ]]; then
                os_version="ubuntu-22-svr"
            elif [[ "$VERSION_ID" == "24.04" ]]; then
                os_version="ubuntu-24-svr"
            fi
        fi
    fi

    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    for i in "${FILES_TO_SYMLINK[@]}"; do

        sourceFile="$(cd && pwd)/iac-instances/dotfiles/$i"
        targetFile="$HOME/.$(printf "%s" "$i" | sed "s/.*\/\(.*\)/\1/g")"

        # Check for OS-specific version
        if [ -n "$os_version" ]; then
            local os_specific_file="$(cd && pwd)/iac-instances/dotfiles/shell/$os_version/$(basename "$i")"
            if [ -f "$os_specific_file" ]; then
                sourceFile="$os_specific_file"
            fi
        fi

        # Check if source file exists
        if [ ! -f "$sourceFile" ]; then
            print_warning "Source file not found: $sourceFile"
            continue
        fi

        if [ ! -e "$targetFile" ] || $skipQuestions; then

            execute \
                "ln -fs $sourceFile $targetFile" \
                "$targetFile → $sourceFile"

        elif [ "$(readlink "$targetFile")" == "$sourceFile" ]; then
            print_success "$targetFile → $sourceFile (already linked)"
        else

            if ! $skipQuestions; then

                ask_for_confirmation "'$targetFile' already exists, do you want to overwrite it?"
                if answer_is_yes; then

                    # Backup existing file before overwriting
                    if [ -f "$targetFile" ] && [ ! -L "$targetFile" ]; then
                        local backup_dir="$HOME/.bash_backups"
                        local filename=$(basename "$targetFile")
                        local backup_file="$backup_dir/${filename}-$(date +%Y%m%d_%H%M%S)"
                        execute "cp $targetFile $backup_file" "Backup existing $filename"
                    fi

                    rm -rf "$targetFile"

                    execute \
                        "ln -fs $sourceFile $targetFile" \
                        "$targetFile → $sourceFile"

                else
                    print_error "$targetFile → $sourceFile (skipped)"
                fi

            else
                # In skip questions mode, backup and overwrite
                if [ -f "$targetFile" ] && [ ! -L "$targetFile" ]; then
                    local backup_dir="$HOME/.bash_backups"
                    local filename=$(basename "$targetFile")
                    local backup_file="$backup_dir/${filename}-$(date +%Y%m%d_%H%M%S)"
                    execute "cp $targetFile $backup_file" "Backup existing $filename"
                fi

                rm -rf "$targetFile"
                execute \
                    "ln -fs $sourceFile $targetFile" \
                    "$targetFile → $sourceFile"
            fi

        fi

    done

}

verify_symlinks() {
    print_in_purple "\n • Verifying symbolic links\n\n"

    local files=(
        ".bash_aliases"
        ".bash_autocompletion"
        ".bash_exports"
        ".bash_functions"
        ".bash_init"
        ".bash_logout"
        ".bash_options"
        ".bash_profile"
        ".bash_prompt"
        ".bashrc"
        ".curlrc"
        ".inputrc"
        ".gitattributes"
        ".gitconfig"
        ".gitignore"
        ".tmux.conf"
        ".vim"
        ".vimrc"
    )

    for file in "${files[@]}"; do
        if [ -L "$HOME/$file" ]; then
            local target=$(readlink "$HOME/$file")
            if [[ "$target" == *"iac-instances/dotfiles"* ]]; then
                print_success "$file is correctly linked"
            else
                print_warning "$file is linked but not to our dotfiles: $target"
            fi
        elif [ -f "$HOME/$file" ]; then
            print_warning "$file exists but is not a symlink"
        else
            print_error "$file does not exist"
        fi
    done
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

main() {

    print_in_purple "\n • Backup Original Bash Files\n\n"
    backup_bash_files "$@"

    print_in_purple "\n • Create symbolic links\n\n"
    create_symlinks "$@"

    # Verify symlinks were created correctly
    verify_symlinks

    print_in_purple "\n • Shell configuration complete!\n\n"
    print_result $? "Please restart your shell or run 'source ~/.bashrc' to apply changes"

}

main "$@"