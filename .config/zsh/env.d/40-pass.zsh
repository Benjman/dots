# Run 'pass git pull' in the background at most once a day.
zmodload zsh/datetime

pass_pull_stamp="$ZSH_CACHE/pass_pull_timestamp"
pass_pull_last=
[[ -r $pass_pull_stamp ]] && pass_pull_last=$(<"$pass_pull_stamp")
# An empty or corrupt stamp counts as never pulled
[[ -z $pass_pull_last || $pass_pull_last == *[^0-9]* ]] && pass_pull_last=0

if (( EPOCHSECONDS - pass_pull_last > 86400 )); then
  if pass git remote >/dev/null 2>&1; then
    # Backgrounded inside a subshell so job control doesn't print "[1] <pid>"
    (pass git pull >/dev/null 2>>"$ZSH_CACHE/pass_pull_error.log" &)
  fi
  echo "$EPOCHSECONDS" >"$pass_pull_stamp"
fi

unset -v pass_pull_stamp pass_pull_last
