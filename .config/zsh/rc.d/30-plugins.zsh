# Plugin configuration
# shellcheck disable=SC2034 # read by zsh-autosuggestions
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=1'

typeset plugin_home="$ZSH_STATE/plugins"

# Each plugin is pinned to a commit; bump the hash to update. A clone whose
# HEAD doesn't match its pin is re-synced at startup, so the pin here is the
# only thing to edit. Reading .git/HEAD is a builtin, so the check is free.
typeset -a plugins=(
  https://github.com/hlissner/zsh-autopair@449a7c3d095bc8f3d78cf37b9549f8bb4c383f3d
  https://github.com/zsh-users/zsh-autosuggestions@85919cd1ffa7d2d5412f6d3fe437ebdbeeec4fc5
  https://github.com/zsh-users/zsh-completions@584dfd5d305158b740ca34be39586e4477545f65
  https://github.com/z-shell/F-Sy-H@f5af74afe220ea139a32506a57711cf085ca49ff
  https://github.com/Aloxaf/fzf-tab@fac145167f7ec1861233c54de0c8900b09c650fe
)

# Sourced by 35-fzf.zsh, in this order, after compinit and fzf. fzf-tab must
# load before the plugins that wrap every widget (autosuggestions, syntax
# highlighting), and the highlighter goes last so it sees all other widgets.
typeset -ga deferred_plugins=(
  fzf-tab
  zsh-autosuggestions
  F-Sy-H
)

# Explicit GIT_DIR/GIT_WORK_TREE so an inherited one (e.g. a shell started
# under `dots`/`dflg`) can't redirect these commands at another repo.
_plugin_git() { GIT_DIR="$1/.git" GIT_WORK_TREE="$1" git "${@:2}"; }

typeset spec repo rev name dir
for spec in "${plugins[@]}"; do
  repo=${spec%@*}
  rev=${spec##*@}
  name=${repo##*/}
  dir="$plugin_home/$name"

  if [[ ! -r "$dir/.git/HEAD" || "$(<"$dir/.git/HEAD")" != "$rev" ]]; then
    echo "Syncing $name to ${rev:0:7}..."
    mkdir -p "$dir"
    if ! { [[ -d "$dir/.git" ]] || _plugin_git "$dir" init -q; } ||
      ! _plugin_git "$dir" fetch -q --depth 1 "$repo" "$rev" ||
      ! _plugin_git "$dir" checkout -q --detach FETCH_HEAD; then
      print -u2 "warning: failed to sync zsh plugin $name"
    fi
  fi

  ((${deferred_plugins[(Ie)$name]})) && continue
  if [[ -f "$dir/$name.plugin.zsh" ]]; then
    source "$dir/$name.plugin.zsh"
  elif [[ -f "$dir/$name.zsh" ]]; then
    source "$dir/$name.zsh"
  fi
done

unset -f _plugin_git
unset -v plugin_home plugins spec repo rev name dir
