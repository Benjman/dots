# Ben's dotfiles

## Installation

Clone the repo and set it up to manage dots:

```sh
git clone --bare git@github.com:Benjman/dots.git ~/.local/share/repos/dots/.git
alias dots="git --git-dir=$HOME/.local/share/repos/dots/.git --work-tree=$HOME"
dots checkout
dots checkout  # see "Git hooks" below
exec zsh
```

## Git hooks

Repos under `~/.local/share/repos/` use the hooks in `.config/git/hooks/`, dispatched per repo by `dispatch.sh` (see its header). This repo's live in `.config/git/hooks/dots/`; notably `post-checkout.d/10-bootstrap.sh` creates XDG dirs and initializes submodules.

The hooks only activate once the first `dots checkout` has written `~/.config/git/config`, so the second checkout is what runs the bootstrap.

The clone path must be exactly `~/.local/share/repos/dots/.git` - the hooks and the `dots`/`dflg`/`lazygit` helpers in `.config/zsh/rc.d/50-git.zsh` depend on it.

Don't run `dots submodule ...`: `git submodule` refuses to run with both a git dir and work tree set. The bootstrap hook handles it instead.
