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
