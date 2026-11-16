export GEM_HOME="$XDG_DATA_HOME/gem"
export GEM_SPEC_CACHE="$GEM_HOME/specs"
[[ -d "$GEM_HOME/bin" ]] && path=("$GEM_HOME/bin" "${path[@]}")

if command -v rbenv >/dev/null; then
  eval "$(rbenv init -)"
fi
