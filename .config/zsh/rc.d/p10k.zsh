if ! yay -Qs zsh-theme-powerlevel10k-git >/dev/null; then
  printf "Download and install Powerlevel10k? [y/n]: "
  read answer
  [[ "$answer" == "Y" || "$answer" == "y" ]] && yay -S zsh-theme-powerlevel10k-git
fi
