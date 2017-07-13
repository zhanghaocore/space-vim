#!/usr/bin/env bash

#   This setup file is based on spf13-vim's bootstrap.sh.
#   Thanks for spf13-vim.

app_name='space-vim'
dot_spacevim="$HOME/.spacevim"
[ -z "$APP_PATH" ] && APP_PATH="$HOME/.space-vim"
[ -z "$REPO_URI" ] && REPO_URI='https://github.com/liuchengxu/space-vim.git'
[ -z "$REPO_BRANCH" ] && REPO_BRANCH='master'
debug_mode='0'
[ -z "$VIM_PLUG_PATH" ] && VIM_PLUG_PATH="$HOME/.vim/autoload"
[ -z "$NEOVIM_PLUG_PATH" ] && VIM_PLUG_PATH="$HOME/.local/share/nvim/site/autoload"
[ -z "$VIM_PLUG_URL" ] && VIM_PLUG_URL='https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'

########## Basic setup tools
help() {
  cat << EOF
usage: $0 [OPTIONS]

    -- help               Show this message
    -- all                Install space-vim for both Vim and NeoVim
    -- vim                Install space-vim for Vim
    -- neovim             Install space-vim for NeoVim
EOF
}

msg() {
    printf '%b\n' "$1" >&2
}

success() {
    if [ "$ret" -eq '0' ];
    then
        msg "\33[32m[✔]\33[0m ${1}${2}"
    fi
}

error() {
    msg "\33[31m[✘]\33[0m ${1}${2}"
    exit 1
}

debug() {
    if [ "$debug_mode" -eq '1' ] && [ "$ret" -gt '1' ];
    then
        msg "An error occurred in function \"${FUNCNAME[$i+1]}\" on line ${BASH_LINENO[$i+1]}, we're sorry for that."
    fi
}

exists() {
    command -v "$1" >/dev/null 2>&1
}

program_exists() {
    local ret='0'
    exists "$1" || { local ret='1'; }

    # fail on non-zero return value
    if [ "$ret" -ne 0 ];
    then
        return 1
    fi

    return 0
}

program_must_exist() {

    # throw error on non-zero return value
    if ! program_exists "$1";
    then
        error "You must have '$1' installed to continue."
    fi
}

lnif() {
    if [ -e "$1" ];
    then
        ln -sf "$1" "$2"
    fi
    ret="$?"
    debug
}

########## Setup function
backup() {
    if [ -e "$1" ];
    then
        msg "\033[1;34m==>\033[0m Attempting to back up your original vim configuration."
        today=$(date +%Y%m%d_%s)
        mv -v "$1" "$1.$today"

        ret="$?"
        success "Your original vim configuration has been backed up."
        debug
    fi
}

sync_repo() {
    local repo_path="$1"
    local repo_uri="$2"
    local repo_branch="$3"
    local repo_name="$4"

    if [ ! -e "$repo_path" ];
    then
        msg "\033[1;34m==>\033[0m Trying to clone $repo_name"
        mkdir -p "$repo_path"
        git clone -b "$repo_branch" "$repo_uri" "$repo_path" --depth=1
        ret="$?"
        success "Successfully cloned $repo_name."
    else
        msg "\033[1;34m==>\033[0m Trying to update $repo_name"
        cd "$repo_path" && git pull origin "$repo_branch"
        ret="$?"
        success "Successfully updated $repo_name"
    fi

    debug
}

create_symlinks() {
    local source_path="$1"
    local target_path="$2"

    lnif "$source_path" "$target_path"

    ret="$?"
    success "Setting up symlinks."

    debug
}

sync_vim_plug() {
    if [ ! -f "'$1'/plug.vim" ];
    then
        curl -fLo "'$1'/plug.vim" --create-dirs "$2"
    fi

    debug
}

generate_dot_spacevim(){
    if [ ! -f "$dot_spacevim" ];
    then
        touch "$dot_spacevim"
        (
        cat <<DOTSPACEVIM
" You can enable the existing layers in space-vim and
" exclude the partial plugins in a certain layer.
" The command Layer is vaild in the function Layers().
" Use exclude option if you don't want the full Layer,
" e.g., Layer 'better-defaults', { 'exclude': 'itchyny/vim-cursorword' }
function! Layers()
    " Default layers, recommended!
    Layer 'fzf'
    Layer 'unite'
    Layer 'better-defaults'
endfunction
" Put your private plugins here.
function! UserInit()
    " Space has been set as the default leader key,
    " if you want to change it, uncomment and set it here.
    " let g:spacevim_leader = "<\Space>"
    " let g:spacevim_localleader = ','
    " Install private plugins
    " Plug 'extr0py/oni'
endfunction
" Put your costom configurations here, e.g., change the colorscheme.
function! UserConfig()
    " If you enable airline layer and have installed the powerline fonts, set it here.
    " let g:airline_powerline_fonts=1
    " color desert
endfunction
DOTSPACEVIM
) >"$dot_spacevim"

    fi
}

set_dot_spacevim(){
    if [ $TEMPLATE ];then
        curl -fLo "$dot_spacevim" "$TEMPLATE"
    else
        generate_dot_spacevim
    fi
}

setup_vim_plug(){
    local system_shell="$SHELL"
    export SHELL='/bin/sh'

    "$1" \
        "+PlugInstall!" \
        "+PlugClean" \
        "+qall"

    export SHELL="$system_shell"

    success "Now updating/installing plugins using vim-plug"

    debug
}

install_for_vim() {

    program_must_exist "git"
    program_must_exist "vim"

    local conf_file="$HOME/.vimrc"

    sync_repo       "$APP_PATH" \
                    "$REPO_URI" \
                    "$REPO_BRANCH" \
                    "$app_name"

    backup          "$conf_file"

    create_symlinks "$APP_PATH/init.vim" \
                    "$conf_file"

    sync_vim_plug   "$VIM_PLUG_PATH" \
                    "$VIM_PLUG_URL"

    set_dot_spacevim

    setup_vim_plug  "vim"

}

install_for_neovim() {

    program_must_exist "git"
    program_must_exist "nvim"

    local conf_file="$HOME/.config/nvim/init.vim"

    sync_repo       "$APP_PATH" \
                    "$REPO_URI" \
                    "$REPO_BRANCH" \
                    "$app_name"

    backup          "$conf_file"

    create_symlinks "$APP_PATH/init.vim" \
                    "$conf_file"

    sync_vim_plug   "$NEOVIM_PLUG_PATH" \
                    "$VIM_PLUG_URL"

    set_dot_spacevim

    setup_vim_plug  "nvim"

}

########## Main()
if [ $# -eq 0 ]; then
    help
    exit 0
else
    for opt in "$@"; do
      case $opt in
        help)
          help
          exit 0
          ;;
        all)
          install_for_vim
          install_for_neovim
          ;;
        vim)
          install_for_vim
          ;;
        neovim)
          install_for_neovim
          ;;
        template=*)
          TEMPLATE="${opt#*=}"
          ;;
        *)
          echo "unknown option: $opt"
          help
          exit 1
          ;;
      esac
    done
fi

msg    "\nThanks for installing \033[1;31m$app_name\033[0m. Enjoy!"
