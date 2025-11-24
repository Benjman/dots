# Bail out early from non-interactive shells unless they're login shells
[[ -o login || -n "${ZSH_SCRIPT}" ]] || return 0

# XDG Base Directory (needed early by many tools, even in scripts)
typeset -g XDG_CACHE_HOME="${XDG_CACHE_HOME:-${HOME}/.cache}"
typeset -g XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-${HOME}/.config}"
typeset -g XDG_DATA_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}"
typeset -g XDG_STATE_HOME="${XDG_STATE_HOME:-${HOME}/.local/state}"
typeset -g XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-${TMPDIR:-/tmp}/zsh-${UID}}"

export XDG_CACHE_HOME XDG_CONFIG_HOME XDG_DATA_HOME XDG_STATE_HOME XDG_RUNTIME_DIR

[[ -d "${XDG_RUNTIME_DIR}" ]] || mkdir -m 700 "${XDG_RUNTIME_DIR}" 2>/dev/null || XDG_RUNTIME_DIR=/tmp

export ZDOTDIR="$XDG_CONFIG_HOME/zsh"

# macOS: run path_helper only once, when PATH is still default
if [[ "$OSTYPE" == darwin* && -x /usr/libexec/path_helper ]]; then
  case "$PATH" in
  */usr/bin:/bin:/usr/sbin:/sbin* | \
    /usr/local/bin:/System/Cryptexes/App/usr/bin:/usr/bin:/bin:/usr/sbin:/sbin)
    eval "$(/usr/libexec/path_helper -s)" 2>/dev/null
    ;;
  esac
fi
