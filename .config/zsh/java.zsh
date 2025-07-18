#!/usr/bin/env zsh

if [[ $(uname) == "Darwin" ]]; then
  export JAVA_HOME="$HOMEBREW_CELLAR/openjdk/current"
elif [[ $(uname) == "Linux" ]]; then
  export JAVA_HOME="$XDG_DATA_HOME/openjdk/current"
fi

if [ -d JAVA_HOME ]; then
  export PATH="$JAVA_HOME/bin:$PATH"
else
  unset JAVA_HOME
fi
