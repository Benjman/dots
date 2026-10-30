#!/bin/sh
[ "$PWD" = "$HOME" ] && exit 0
git submodule update --init --depth 1 || exit
cmake -B build -S . || exit
make --directory build || exit
