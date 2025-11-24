[[ -o interactive ]] || return 0

export ZSH_CACHE_DIR="$XDG_CACHE_HOME/zsh"
export ZSH_STALE_PATH="$XDG_RUNTIME_DIR/zsh_stale"

mkdir -p -- \
  "$XDG_CACHE_HOME/$USER" \
  "$XDG_CONFIG_HOME/$USER" \
  "$XDG_DATA_HOME/$USER" \
  "$XDG_STATE_HOME/$USER" \
  "$ZDOTDIR/env.d" \
  "$ZDOTDIR/rc.d" \
  "$ZSH_CACHE_DIR" \
  "$XDG_RUNTIME_DIR" 2>/dev/null

HISTFILE="$ZSH_CACHE_DIR/history"
HISTSIZE=10000
SAVEHIST=10000
setopt HIST_EXPIRE_DUPS_FIRST HIST_IGNORE_ALL_DUPS HIST_IGNORE_SPACE
setopt HIST_FIND_NO_DUPS HIST_SAVE_NO_DUPS SHARE_HISTORY

autoload -Uz compinit
if [[ -n $ZSH_CACHE_DIR/zcompdump(.Nmh+7) ]]; then
  compinit -C -d "$ZSH_CACHE_DIR/zcompdump"
else
  compinit -d "$ZSH_CACHE_DIR/zcompdump"
fi
zstyle ':completion:*' menu select
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"

bindkey -v
export KEYTIMEOUT=1

alias ll="ls --color=auto -lah"
alias ls="ls --color=auto"

(( $+commands[nproc] )) && alias make='make -j$(nproc)'

for file in "$ZDOTDIR"/rc.d/*.zsh(N); do
  . "$file"
done
unset -v file
