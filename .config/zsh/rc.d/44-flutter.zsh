[[ $OSTYPE == darwin* ]] && alias flutter="flutter -d macos"
[[ $OSTYPE == linux* ]] && alias flutter="flutter -d linux"
[[ -d "$PUB_CACHE/bin" ]] && path+=("$PUB_CACHE/bin")

alias fl=flutter
