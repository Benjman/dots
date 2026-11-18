typeset submodule_dir="$ZSH_STATE/plugins/powerlevel10k"

if [[ ! -f "$submodule_dir/powerlevel10k.zsh-theme" ]]; then
  print -u2 "warning: powerlevel10k not found at $submodule_dir — run: dots submodule update --init"
  return 1
fi

POWERLEVEL9K_CONFIG_FILE="$ZSH_STATE/p10k"
[[ -n "$XDG_SESSION_TYPE" ]] && POWERLEVEL9K_CONFIG_FILE+="-$XDG_SESSION_TYPE"
[[ -r "$POWERLEVEL9K_CONFIG_FILE" ]] && source "$POWERLEVEL9K_CONFIG_FILE"
# Overrides the config's value: plugin syncs and the git identity warning
# legitimately print during init, which instant prompt would otherwise flag.
# shellcheck disable=SC2034 # read by powerlevel10k
POWERLEVEL9K_INSTANT_PROMPT=quiet

source "$submodule_dir/powerlevel10k.zsh-theme"
