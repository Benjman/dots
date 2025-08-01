dir="${ZDOTDIR:-$HOME/.config/zsh}"
for file in $dir/env/*.zsh; do
  [ -r "$file" ] && source "$file"
done
unset dir file
