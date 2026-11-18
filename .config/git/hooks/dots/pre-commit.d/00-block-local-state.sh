#!/bin/sh
# Block and auto-unstage any private files (.local/state/, private hook dirs) from being committed.

# Submodules registered in .gitmodules (e.g. powerlevel10k under
# .local/state/zsh/plugins/) are tracked on purpose, not leaked state.
# Usage: not_submodule <.gitmodules blob>. Guarded because grep -v with an
# empty pattern would drop every line and hide real leaks.
not_submodule() {
  submodules=$(git config --blob "$1" --get-regexp '^submodule\..*\.path$' 2>/dev/null | cut -d' ' -f2-)
  if [ -n "$submodules" ]; then
    grep -vxF -e "$submodules"
  else
    cat
  fi
}

# Private paths: .local/state/, plus per-repo hook dirs listed as private in
# the dots repo's info/exclude (--no-index so force-added files still match)
private_paths() {
  paths=$(cat)
  printf '%s\n' "$paths" | grep '^\.local/state/' | not_submodule :.gitmodules
  printf '%s\n' "$paths" | grep '^\.config/git/hooks/' | git check-ignore --no-index --stdin
}

bad_files=$(git diff --cached --name-only | private_paths)

[ -z "$bad_files" ] && exit 0

echo "pre-commit: blocked private files (.local/state/, private hook dirs) from being committed." >&2
echo "Unstaging:" >&2
echo "$bad_files" | while IFS= read -r f; do
  echo "  $f" >&2
  git restore --staged -- "$f"
done
echo "These files have been unstaged. Commit aborted." >&2
exit 1
