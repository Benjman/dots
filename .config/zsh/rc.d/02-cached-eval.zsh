# Source a tool's shell-init output (e.g. `fzf --zsh`) from a cache instead of
# forking the tool on every shell start. The cache is regenerated when the
# binary is replaced: its resolved path is stamped on the first line, which
# catches Homebrew upgrades that swap the symlink to a new Cellar version.
#
# Only for tools whose output is static; `fnm env` creates a per-shell
# directory and must not be cached.
#
#   _cached_eval <name> <command> [args...]
_cached_eval() {
  # shellcheck disable=SC2154 # $commands is zsh's command hash table
  local name=$1 bin=${commands[$2]}
  [[ -n $bin ]] || return 1
  local cache="$ZSH_CACHE/eval/$name.zsh" stamp="# ${bin:A}" first=
  [[ -r $cache ]] && read -r first <"$cache"
  if [[ $first != "$stamp" || $bin -nt $cache ]]; then
    mkdir -p "${cache:h}"
    { echo "$stamp" && "${@:2}"; } >"$cache" || { rm -f "$cache"; return 1; }
  fi
  source "$cache"
}
