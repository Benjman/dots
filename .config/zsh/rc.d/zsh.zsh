zstyle :compinstall filename "$ZDOTDIR/.zshrc"

autoload -z edit-command-line
zle -N edit-command-line
bindkey -M vicmd E edit-command-line
bindkey '^R' history-incremental-search-backward

_refresh_zsh() {
  if [ -f $ZSH_UPDATE_TRIGGER_PATH ]; then
    echo "Sourcing $HOME/.zshrc..."
    source ~/.zshrc
    rm -f "$ZSH_UPDATE_TRIGGER_PATH"
  fi
}

zshc() {
  cd "$ZDOTDIR"
  case "$1" in
  "d") pwd ;;
  *)
    nvim
    # The file $ZSH_STALE_PATH is created via a Neovim autocmd.
    # See $XDG_CONFIG_HOME/nvim/lua/custom/autocmds/zsh.lua
    if [[ -f "$ZSH_STALE_PATH" ]]; then
      echo ":: Sourcing zsh config..."
      rm "$ZSH_STALE_PATH"
      exec zsh
    fi
    cd - >/dev/null
    ;;
  esac
}
