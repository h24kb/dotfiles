#!/bin/bash
# this is safe to run multiple times and will prompt you about anything unclear

answer_is_yes() {
    [[ "$REPLY" =~ ^[Yy]$ ]] \
        && return 0 \
        || return 1
}

ask() {
    print_question "$1"
    read
}

ask_for_confirmation() {
    print_question "$1 (y/n) "
    read -n 1
    printf "\n"
}

ask_for_sudo() {
    # Ask for the administrator password upfront
    sudo -v
    # Update existing `sudo` time stamp until this script has finished
    # https://gist.github.com/cowboy/3118588
    while true; do
        sudo -n true
        sleep 60
        kill -0 "$$" || exit
    done &> /dev/null &
}

cmd_exists() {
    [ -x "$(command -v "$1")" ] \
        && printf 0 \
        || printf 1
}

execute() {
    $1 &> /dev/null
    print_result $? "${2:-$1}"
}

get_answer() {
    printf "$REPLY"
}

get_os() {
    declare -r OS_NAME="$(uname -s)"
    local os=""

    if [ "$OS_NAME" == "Darwin" ]; then
        os="osx"
    elif [ "$OS_NAME" == "Linux" ] && [ -e "/etc/lsb-release" ]; then
        os="ubuntu"
    fi

    printf "%s" "$os"
}

is_git_repository() {
    [ "$(git rev-parse &>/dev/null; printf $?)" -eq 0 ] \
        && return 0 \
        || return 1
}

mkd() {
    if [ -n "$1" ]; then
        if [ -e "$1" ]; then
            if [ ! -d "$1" ]; then
                print_error "$1 - a file with the same name already exists!"
            else
                print_success "$1"
            fi
        else
            execute "mkdir -p $1" "$1"
        fi
    fi
}

print_error() {
    # Print output in red
    printf "\e[0;31m  [✖] $1 $2\e[0m\n"
}

print_info() {
    # Print output in purple
    printf "\n\e[0;35m $1\e[0m\n\n"
}

print_question() {
    # Print output in yellow
    printf "\e[0;33m  [?] $1\e[0m"
}

print_result() {
    [ $1 -eq 0 ] \
        && print_success "$2" \
        || print_error "$2"

    [ "$3" == "true" ] && [ $1 -ne 0 ] \
        && exit
}

print_success() {
    # Print output in green
    printf "\e[0;32m  [✔] $1\e[0m\n"
}

link_file(){
    sourceFile=$1
    targetFile=$2
    if [ -e "$targetFile" ]; then
        if [ "$(readlink "$targetFile")" != "$sourceFile" ]; then
            ask_for_confirmation "'$targetFile' already exists, do you want to overwrite it?"
            if answer_is_yes; then
                rm -rf "$targetFile"
                execute "ln -fs $sourceFile $targetFile" "$targetFile → $sourceFile"
            else
                print_error "$targetFile → $sourceFile"
            fi
        else
            print_success "$targetFile → $sourceFile"
        fi
    else
        execute "ln -fs $sourceFile $targetFile" "$targetFile → $sourceFile"
    fi
}

#
# actual symlink stuff
#
# finds all .dotfiles in this folder
declare -a FILES_TO_SYMLINK=$(find . -type f -maxdepth 1 -name ".*" -not -name .DS_Store -not -name .git -not -name .gitignore | sed -e 's|//|/|' | sed -e 's|./.|.|')
FILES_TO_SYMLINK="$FILES_TO_SYMLINK .zsh-custom .pip .spacemacs.d" # add in vim and the binaries

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
main() {
    local i=""
    local sourceFile=""
    local targetFile=""
    for i in ${FILES_TO_SYMLINK[@]}; do
        sourceFile="$(pwd)/$i"
        targetFile="$HOME/$(printf "%s" "$i" | sed "s/.*\/\(.*\)/\1/g")"
        link_file "$sourceFile" "$targetFile"
    done
}

# Shadowsocks user-rules
[[ -d ~/.ShadowsocksX-NG ]] && link_file "$(pwd)/user-rule.txt" "$HOME/.ShadowsocksX-NG/user-rule.txt"

# vim 插件使用vundle进行管理，需要预先初始化
if [[ ! -d ~/.vim/bundle/Vundle.vim ]]; then
    print_info "install Vundle.vim..."
    mkdir -p ~/.vim/bundle
    git clone https://github.com/VundleVim/Vundle.vim.git ~/.vim/bundle/Vundle.vim
fi

# oh-my-zsh
[[ ! -d ~/.oh-my-zsh ]] && print_info "install oh-my-zsh..." && git clone git://github.com/robbyrussell/oh-my-zsh.git ~/.oh-my-zsh

# spacemacs
if [[ ! -d ~/.emacs.d ]]; then
    print_info "install spacemacs..."
    git clone https://github.com/syl20bnr/spacemacs ~/.emacs.d
elif [[ ! -d ~/.emacs.d/.git || `cd ~/.emacs.d/ && git remote -v | grep syl20bnr/spacemacs | wc -l` -eq "0" ]]; then
    ask_for_confirmation ".emacs.d already exists, do you want to overwrite it with syl20bnr/spacemacs?"
    if answer_is_yes; then
        rm -rf ~/.emacs.d
        git clone https://github.com/syl20bnr/spacemacs ~/.emacs.d
    else
        print_error "spacemacs is not installed correctly."
    fi
fi
if [[ -f ~/.spacemacs ]]; then
    ask_for_confirmation "~/.spacemacs already exists, do you want to remove it? (We used the .spacemacs.d directory within this repo.)"
    if answer_is_yes; then
        rm ~/.spacemacs && print_success "~/.spacemacs is removed."
    else
        print_error "~/.spacemacs is exists, the ~/.spacemacs.d will not be loaded."
    fi
fi


main

