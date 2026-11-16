#!/bin/sh
# Idempotent first-run setup: ensure XDG base dirs exist, submodules are
# initialized, and $HOME is sparse-checked-out. Safe to run on every checkout (branch switches included) since
# every step is a no-op once done.

: "${XDG_CACHE_HOME:=$HOME/.cache}"
: "${XDG_CONFIG_HOME:=$HOME/.config}"
: "${XDG_DATA_HOME:=$HOME/.local/share}"
: "${XDG_STATE_HOME:=$HOME/.local/state}"

for d in "$XDG_CACHE_HOME/zsh" "$XDG_STATE_HOME/zsh/env" "$XDG_STATE_HOME/zsh/rc" \
  "$XDG_STATE_HOME/git" "$XDG_DATA_HOME/repos" "$XDG_DATA_HOME/wallpapers" \
  "$XDG_CONFIG_HOME/npm"; do
  [ -d "$d" ] || mkdir -p "$d"
done

# git submodule specifically requires GIT_DIR + a cwd inside the work tree,
# not GIT_WORK_TREE — the two combined make submodule refuse to run.
dots_git() {
  GIT_DIR="$XDG_DATA_HOME/repos/dots/.git" git -C "$HOME" "$@"
}

if dots_git submodule status 2>/dev/null | grep -q '^-'; then
  echo "post-checkout: initializing submodules..."
  dots_git submodule update --init
fi

# Keep repo plumbing out of $HOME via a sparse checkout; linked worktrees keep
# full checkouts since the setting lands in the bare dir's config.worktree.
# git still reads .gitignore/.gitmodules from the index when they're absent.
# Unlike submodule, sparse-checkout needs an explicit GIT_WORK_TREE.
sparse_patterns='/*
!/.github/
!/.gitignore
!/.gitmodules
!/readme.md'

dots_wt_git() {
  GIT_DIR="$XDG_DATA_HOME/repos/dots/.git" GIT_WORK_TREE="$HOME" git -C "$HOME" "$@"
}

if [ -d "$XDG_DATA_HOME/repos/dots/.git" ] &&
  [ "$(dots_wt_git sparse-checkout list 2>/dev/null)" != "$sparse_patterns" ]; then
  echo "post-checkout: hiding repo plumbing from \$HOME via sparse-checkout..."
  printf '%s\n' "$sparse_patterns" | dots_wt_git sparse-checkout set --no-cone --stdin
fi
