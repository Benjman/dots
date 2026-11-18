_cached_eval fzf fzf --zsh

# Plugins held back by 30-plugins.zsh until compinit and fzf are loaded; the
# order of $deferred_plugins is significant, see there.
typeset name dir
# shellcheck disable=SC2154 # set in 30-plugins.zsh
for name in "${deferred_plugins[@]}"; do
  dir="$ZSH_STATE/plugins/$name"
  if [[ -f "$dir/$name.plugin.zsh" ]]; then
    source "$dir/$name.plugin.zsh"
  elif [[ -f "$dir/$name.zsh" ]]; then
    source "$dir/$name.zsh"
  fi
done
unset -v deferred_plugins name dir
