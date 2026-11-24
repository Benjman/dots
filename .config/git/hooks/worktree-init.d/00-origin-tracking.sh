#!/bin/sh
# Bare clones skip two things a normal clone sets up: a fetch refspec (so
# there are no origin/* remote-tracking branches) and an upstream for the
# checked-out branch. Add both; each step is a no-op once in place.

git remote get-url origin >/dev/null 2>&1 || exit 0

if [ -z "$(git config --get-all remote.origin.fetch)" ]; then
  echo "origin: adding fetch refspec for origin/* branches"
  git config remote.origin.fetch '+refs/heads/*:refs/remotes/origin/*'
  # Don't fail the checkout over a network hiccup; the next fetch catches up
  git fetch --quiet origin || echo "origin: fetch failed, run 'git fetch' later" >&2
fi

branch=$(git symbolic-ref --quiet --short HEAD) || exit 0
git rev-parse --quiet --verify '@{upstream}' >/dev/null 2>&1 && exit 0
git show-ref --verify --quiet "refs/remotes/origin/$branch" || exit 0
git branch --quiet --set-upstream-to="origin/$branch" "$branch"
echo "origin: $branch now tracks origin/$branch"
