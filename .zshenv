: ${XDG_CACHE_HOME:=$HOME/.cache}
: ${XDG_CONFIG_HOME:=$HOME/.config}
: ${XDG_DATA_HOME:=$HOME/.local/share}
: ${XDG_STATE_HOME:=$HOME/.local/state}
: ${XDG_RUNTIME_DIR:=/run/user/$UID}

typeset -gx ZDOTDIR=$XDG_CONFIG_HOME/zsh
typeset -gx ZSH_CACHE_DIR=$XDG_CACHE_HOME/zsh

if [[ ! -d $XDG_RUNTIME_DIR || ! -w $XDG_RUNTIME_DIR ]]; then
  if [[ $OSTYPE == darwin* ]] && dir=$(getconf DARWIN_USER_TEMP_DIR 2>/dev/null) && [[ -d $dir ]]; then
    XDG_RUNTIME_DIR=$dir
  else
    XDG_RUNTIME_DIR=/tmp/zsh-runtime-$UID
  fi
fi

export XDG_CACHE_HOME XDG_CONFIG_HOME XDG_DATA_HOME XDG_STATE_HOME XDG_RUNTIME_DIR

{
  local dirs=(
    "$HOME/.local/bin"
    "$XDG_CACHE_HOME"/{zsh,$USER}
    "$XDG_CONFIG_HOME"/$USER
    "$XDG_DATA_HOME"/$USER
    "$XDG_RUNTIME_DIR"
    "$XDG_STATE_HOME"/$USER
    "$ZDOTDIR"/{env.d,rc.d}
    "$ZSH_CACHE_DIR"
  )
  command mkdir -pm 700 -- $dirs 2>/dev/null ||:
} always { unfunction -m mkdir 2>/dev/null }
