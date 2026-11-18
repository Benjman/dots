#!/bin/sh
# Block pushes that contain commits with private files (.local/state/, private hook dirs).

# Private paths: .local/state/, plus per-repo hook dirs listed as private in
# the dots repo's info/exclude (--no-index so force-added files still match)
private_paths() {
  paths=$(cat)
  printf '%s\n' "$paths" | grep '^\.local/state/'
  printf '%s\n' "$paths" | grep '^\.config/git/hooks/' | git check-ignore --no-index --stdin
}

while IFS=' ' read -r _ local_sha _ remote_sha; do
  # Branch deletion: nothing is being sent
  case $local_sha in *[!0]*) ;; *) continue ;; esac

  # Every commit being pushed: those after the remote's tip, or, for a new
  # branch (or a remote tip we don't have locally), those not on any remote.
  set -- "$local_sha" --not --remotes
  case $remote_sha in
  *[!0]*)
    if git cat-file -e "$remote_sha^{commit}" 2>/dev/null; then
      set -- "$remote_sha..$local_sha"
    fi
    ;;
  esac

  # Per-commit file lists (-m includes merges), not the net diff, so a file
  # added in one commit and deleted in a later one is still caught.
  bad_files=$(git log -m --name-only --format= "$@" | sort -u | private_paths)

  if [ -n "$bad_files" ]; then
    echo "pre-push: refusing to push — commits contain private files (.local/state/, private hook dirs):" >&2
    echo "$bad_files" | while IFS= read -r f; do
      echo "  $f" >&2
    done
    echo "Remove these files from the affected commits before pushing." >&2
    exit 1
  fi
done
