# Toolchain env lives in env.d (login shell) rather than rc.d, so it's
# exported once and inherited by everything the session starts, not only
# interactive shells.

if [[ $OSTYPE == darwin* ]]; then
  MAKEFLAGS="-j$(sysctl -n hw.ncpu)"
  CMAKE_BUILD_PARALLEL_LEVEL=$(sysctl -n hw.ncpu)
  export MAKEFLAGS CMAKE_BUILD_PARALLEL_LEVEL
fi

if [[ $OSTYPE == linux* ]]; then
  MAKEFLAGS="-j$(nproc)"
  CMAKE_BUILD_PARALLEL_LEVEL=$(nproc)
  export MAKEFLAGS CMAKE_BUILD_PARALLEL_LEVEL
fi

if [[ $OSTYPE == darwin* && -n $HOMEBREW_PREFIX ]]; then
  JAVA_HOME="$HOMEBREW_PREFIX/opt/openjdk"
elif [[ $OSTYPE == linux* ]]; then
  JAVA_HOME="$XDG_DATA_HOME/openjdk/current"
fi
if [[ -n $JAVA_HOME && -d $JAVA_HOME/bin ]]; then
  export JAVA_HOME
  path=("$JAVA_HOME/bin" "${path[@]}")
else
  unset JAVA_HOME
fi

[[ -d "$GEM_HOME/bin" ]] && path=("$GEM_HOME/bin" "${path[@]}")
[[ -d "$FLUTTER_HOME/bin" ]] && path=("$FLUTTER_HOME/bin" "${path[@]}")
