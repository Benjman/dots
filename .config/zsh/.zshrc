[[ -o interactive ]] || return 0

# p10k instant prompt: draw the last prompt immediately and load the rest of
# the config behind it. Skipped on Linux VTs, where 62-loadkeys.zsh may ask
# for a sudo password and 61-hypr.zsh launches the compositor.
if [[ $TTY != /dev/tty[0-9]* && -r "$XDG_CACHE_HOME/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "$XDG_CACHE_HOME/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Tracked fragments first, machine-local ones last so they can override.
for f in {"$ZDOTDIR"/rc.d,"$ZSH_STATE"/rc}/*.zsh(N); do
  . "$f"
done
unset -v f
