#!/usr/bin/env zsh

export EDITOR="nvim"
export PAGER="less"
export REPOS="$XDG_DATA_HOME/repos"

[[ -d $HOME/.local/bin ]] && export PATH="$HOME/.local/bin:$PATH"
