export FLUTTER_HOME="$REPOS/flutter"
if [[ -d "$FLUTTER_HOME/bin" ]]; then
  path=("$FLUTTER_HOME/bin" "${path[@]}")
fi

[[ $OSTYPE == darwin* ]] && alias flutter="flutter -d macos"
[[ $OSTYPE == linux* ]] && alias flutter="flutter -d linux"
[[ -d "$PUB_CACHE/bin" ]] && path+=("$PUB_CACHE/bin")

alias fl=flutter
