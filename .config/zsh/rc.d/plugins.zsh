# 99-plugins.zsh – sourced only once, never again until you delete the lockfile
local plugin_lock="$XDG_CACHE_HOME/zsh/.plugins-installed"

if [[ ! -f "$plugin_lock" ]]; then
  local plugin_home="${XDG_DATA_HOME:-$HOME/.local/share}/zsh"

  _clone() {
    local name=$1 repo=$2
    [[ -d "$plugin_home/$name" ]] && return
    echo "Installing $name..."
    git clone --depth 1 "$repo" "$plugin_home/$name" >/dev/null 2>&1
  }

  _clone fzf-tab                      https://github.com/Aloxaf/fzf-tab
  _clone zsh-autopair                 https://github.com/hlissner/zsh-autopair
  _clone fast-syntax-highlighting     https://github.com/zdharma-continuum/fast-syntax-highlighting
  _clone zsh-autosuggestions          https://github.com/zsh-users/zsh-autosuggestions
  _clone zsh-completions              https://github.com/zsh-users/zsh-completions
  _clone zsh-history-substring-search https://github.com/zsh-users/zsh-history-substring-search

  touch "$plugin_lock"
fi

# Now actually load them (this part runs every shell, but is cheap)
local p
for p in "${XDG_DATA_HOME:-$HOME/.local/share}/zsh"/{fzf-tab,fast-syntax-highlighting,zsh-autosuggestions,zsh-autopair,zsh-completions,zsh-history-substring-search}; do
  [[ -f "$p/${p:t}.zsh" ]]        && source "$p/${p:t}.zsh"
  [[ -f "$p/${p:t}.plugin.zsh" ]] && source "$p/${p:t}.plugin.zsh"
done

unset -v p plugin_lock

# fast-syntax-highlighting and autosuggestions recommend these lines
[[ -n ${FAST_HIGHLIGHT+1} ]] || FAST_HIGHLIGHT=()
FAST_HIGHLIGHT[chroma-man]=1
