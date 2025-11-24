export BROWSER=firefox
export EDITOR=nvim
export PAGER=less
export VISUAL=nvim

export REPOS="$XDG_DATA_HOME/repos"
export NEXTCLOUD_DIR="$XDG_DATA_HOME/Nextcloud"
export PASSWORD_STORE_DIR="$REPOS/password-store/"

(( ${+ZSH_VERSION} )) && [[ -o interactive ]] && {
  export FZF_DEFAULT_OPTS="--height=40% --layout=reverse --border=sharp"
  export LESS="-iMRx4 -j.5"
  export MANPAGER="nvim +Man!"
}

typeset -U path fpath cdpath manpath
typeset -T LD_LIBRARY_PATH ld_library_path

path=(
  "$HOME/.local/bin"
  "$HOME/bin"
  "$XDG_DATA_HOME/cargo/bin"
  "$XDG_DATA_HOME/go/bin"
  "$XDG_DATA_HOME/npm/bin"
  "$XDG_DATA_HOME/gem/ruby/"*/bin(N/)
  /opt/homebrew/bin(N/)
  /usr/local/bin(N/)
  $path
)

# ── Homebrew – only eval if brew is installed and not already in PATH ──
if (( ${+commands[brew]} )) && [[ -z "$HOMEBREW_PREFIX" ]]; then
  # This is ~50–80 ms faster than running `brew shellenv` unconditionally
  eval "$(brew shellenv)"
fi

if [[ -d "$ZDOTDIR/env.d" ]]; then
  setopt nullglob
  for f in "$ZDOTDIR"/env.d/*.zsh(N); do
    . "$f"
  done
  unsetopt nullglob
fi

if [[ -x "/opt/homebrew/bin/brew" ]] && (( ! ${path[(Ie)/opt/homebrew/bin]} )); then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi
