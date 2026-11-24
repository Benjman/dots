# Layer machine-specific settings over the tracked $CLAUDE_CONFIG_DIR/settings.json.
claude() {
  local cfg="$XDG_STATE_HOME/claude/settings.json"
  if [[ -f "$cfg" ]]; then
    command claude --settings "$cfg" "$@"
  else
    command claude "$@"
  fi
}
