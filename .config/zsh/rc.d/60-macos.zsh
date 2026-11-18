[[ $OSTYPE != darwin* ]] && return 0

symlink_config_dir() {
  local name="$1"
  if [[ -z "$name" ]]; then
    echo "Usage: _symlink_config_dir <config_dir_name>" >&2
    return 1
  fi
  local src="$XDG_CONFIG_HOME/$name"
  local dest="$HOME/Library/Application Support/$name"
  if [[ ! -L "$dest" && -d "$src" ]]; then
    if [[ -e "$dest.bak" ]]; then
      echo "Backup $dest.bak already exists. Aborting." >&2
      return 1
    fi
    if [[ -e "$dest" ]]; then
      echo "Backing up existing directory at: $dest → $dest.bak"
      mv "$dest" "$dest.bak" || {
        echo "Failed to backup $dest" >&2
        return 1
      }
    fi
    echo "Creating symlink: $src → $dest"
    ln -s "$src" "$dest" || {
      echo "Failed to create symlink" >&2
      return 1
    }
  fi
}

open() {
  if [[ $# -eq 1 && -f "$1" ]]; then
    local mime
    mime=$(file --mime-type -b "$1" 2>/dev/null)
    if [[ "$mime" == text/* ]]; then
      $EDITOR "$1"
      return
    fi
  fi
  command open "$@"
}

symlink_config_dir lazygit
symlink_config_dir qutebrowser
unset -f symlink_config_dir

# launchctl's environment lasts for the login session, so only push it when
# the values or the session ($SECURITYSESSIONID) changed, instead of forking
# launchctl three times in every new shell.
launchctl_stamp="$XDG_RUNTIME_DIR/zsh-launchctl-env"
launchctl_env="$SECURITYSESSIONID BROWSER=$BROWSER EDITOR=$EDITOR PAGER=$PAGER"
if [[ ! -r $launchctl_stamp || "$(<"$launchctl_stamp")" != "$launchctl_env" ]]; then
  [[ -n "$BROWSER" ]] && launchctl setenv BROWSER "$BROWSER"
  [[ -n "$EDITOR" ]] && launchctl setenv EDITOR "$EDITOR"
  [[ -n "$PAGER" ]] && launchctl setenv PAGER "$PAGER"
  echo "$launchctl_env" >"$launchctl_stamp"
fi
unset -v launchctl_stamp launchctl_env

# Terminal.app starts login shells at / ; don't clobber the cwd of
# every other interactive shell (new kitty tabs, tmux splits, subshells).
[[ -o login && $PWD == / ]] && { cd "$HOME" || return; }
