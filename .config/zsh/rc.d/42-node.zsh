# Not cached via _cached_eval: `fnm env` creates a per-shell multishell dir.
command -v fnm >/dev/null 2>&1 && eval "$(fnm env --use-on-cd)"
