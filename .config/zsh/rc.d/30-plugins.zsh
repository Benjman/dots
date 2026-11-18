# Plugin configuration
# shellcheck disable=SC2034 # read by zsh-autosuggestions
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=1'

typeset plugin_home="$ZSH_STATE/plugins"

typeset -a plugins=(
  https://github.com/hlissner/zsh-autopair
  https://github.com/zsh-users/zsh-autosuggestions
  https://github.com/zsh-users/zsh-completions
  https://github.com/z-shell/F-Sy-H
  https://github.com/Aloxaf/fzf-tab
)

# Plugins that must be sourced after compinit; see 35-fzf.zsh
typeset -a deferred_plugins=(
  fzf-tab
)

typeset repo name dir
for repo in "${plugins[@]}"; do
  name=${repo##*/}
  dir="$plugin_home/$name"

  if [[ ! -d "$dir" ]]; then
    echo "Installing $name..."
    git clone --depth 1 "$repo" "$dir" >/dev/null 2>&1
  fi

  (( ${deferred_plugins[(Ie)$name]} )) && continue
  [[ -f "$dir/$name.zsh" ]] && source "$dir/$name.zsh"
  [[ -f "$dir/$name.plugin.zsh" ]] && source "$dir/$name.plugin.zsh"
done

unset -v plugin_home plugins deferred_plugins repo name dir
