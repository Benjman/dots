#!/bin/sh
# Keep submodules in step with the superproject after HEAD moves. Symlinked
# into post-merge.d and post-rewrite.d. submodule.recurse makes checkout, pull
# and reset move or remove existing submodules on their own; this covers what
# it doesn't: URL changes in .gitmodules and cloning newly added submodules.

# shellcheck disable=SC2046
unset $(git rev-parse --local-env-vars)

: "${XDG_DATA_HOME:=$HOME/.local/share}"

# The $HOME work tree hangs off the bare repo (core.bare=true), so it needs
# GIT_WORK_TREE too, or submodule refuses to run without a working tree.
# git clears both before running anything inside a submodule.
dots_git() {
  if [ "$PWD" = "$HOME" ]; then
    GIT_DIR="$XDG_DATA_HOME/repos/dots/.git" GIT_WORK_TREE="$HOME" git "$@"
  else
    git "$@"
  fi
}

# Shared config, not --worktree, so every worktree and $HOME get it
[ "$(dots_git config --bool submodule.recurse)" = true ] ||
  dots_git config submodule.recurse true

dots_git submodule sync -q --recursive
dots_git submodule update -q --init --recursive
