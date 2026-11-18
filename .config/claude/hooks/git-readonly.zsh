#!/usr/bin/env zsh
# shellcheck shell=bash # zsh; lint as the closest supported dialect
# PreToolUse hook: only allow read-only git and gh commands, unless the Bash
# sandbox is provably enforced.
#
# Where it is (see sandbox_probe: on, no unsandboxed retries, fail if
# unavailable, real repos' .git write-protected, and nothing of higher
# precedence such as org-managed settings turning any of that off), git
# commands that only touch history, refs or the index are allowed too: they
# work in scratch repos and the sandbox stops them on real ones. Commands
# that can discard working-tree changes stay denied either way, since the
# sandbox doesn't protect working files.
#
# Reads the Bash tool call from stdin, finds every git/gh invocation in the
# command (across ;, &&, |, $(...), backticks, sh -c, eval, xargs, find -exec,
# env/sudo/timeout wrappers) and denies the call unless each one is on the
# allowlist below. Anything unrecognized (including git aliases) is denied.
#
# Tokenizing uses zsh's own parser via ${(z)...}.

# shellcheck disable=SC2329 # git_*_ok are dispatched by name from check_git
emulate -R zsh
setopt extended_glob

reason=""
flags=()
pos=()
vopts=()

deny() { reason=$1; return 1; }

# in_list <value> <word>... -> value is one of the words
in_list() {
  local v=$1 w
  shift
  for w in "$@"; do [[ $w == "$v" ]] && return 0; done
  return 1
}

# Split args into $flags (option names) and $pos (positionals). Options in
# $vopts consume the next arg unless written --opt=value.
split_args() {
  flags=()
  pos=()
  local a name
  while (( $# )); do
    a=$1
    shift
    if [[ $a == -- ]]; then
      pos+=("$@")
      break
    elif [[ $a == -?* ]]; then
      name=${a%%=*}
      flags+=("$name")
      if in_list "$name" "${vopts[@]}" && [[ $a != *=* ]] && (( $# )); then shift; fi
    else
      pos+=("$a")
    fi
  done
  vopts=()
}

# -av -> -a -v
expand_short() {
  local -a out
  local f
  local -i k
  for f in "${flags[@]}"; do
    if [[ $f == -[A-Za-z][A-Za-z]## ]]; then
      for (( k = 1; k < ${#f}; k++ )); do out+=("-${f:$k:1}"); done
    else
      out+=("$f")
    fi
  done
  flags=("${out[@]}")
}

# flags_within <word>... -> every entry of $flags is one of the words
flags_within() {
  local f
  for f in "${flags[@]}"; do in_list "$f" "$@" || return 1; done
}

# has_flag <word>... -> any of the words is in $flags
has_flag() {
  local f
  for f in "$@"; do in_list "$f" "${flags[@]}" && return 0; done
  return 1
}

# --- git ---------------------------------------------------------------------

GIT_READ=(
  annotate blame cat-file check-attr check-ignore cherry count-objects
  describe diff diff-files diff-index diff-tree for-each-ref grep help log
  ls-files ls-remote ls-tree merge-base name-rev range-diff rev-list
  rev-parse shortlog show show-branch show-ref status var verify-commit
  verify-tag version whatchanged
)
REF_FILTERS=(--contains --no-contains --merged --no-merged --points-at --sort --format)

git_branch_ok() {
  vopts=("${REF_FILTERS[@]}")
  split_args "$@"
  expand_short
  flags_within -a --all -r --remotes -v --verbose -l --list --show-current \
    -i --ignore-case --color --no-color --column --no-column --abbrev \
    --no-abbrev -q --quiet --omit-empty "${REF_FILTERS[@]}" || return 1
  (( ! ${#pos[@]} )) || has_flag -l --list
}

git_tag_ok() {
  vopts=("${REF_FILTERS[@]}")
  split_args "$@"
  local f
  for f in "${flags[@]}"; do
    [[ $f == -n[0-9]# ]] && continue
    in_list "$f" -l --list -v --verify -i --ignore-case --color --no-color \
      --column --no-column --omit-empty "${REF_FILTERS[@]}" || return 1
  done
  (( ! ${#pos[@]} )) || has_flag -l --list -v --verify
}

git_remote_ok() {
  split_args "$@"
  (( ${#pos[@]} )) || { flags_within -v --verbose; return; }
  in_list "${pos[1]}" show get-url
}

git_config_ok() {
  vopts=(-f --file --blob --type --default)
  split_args "$@"
  has_flag --add --replace-all --unset --unset-all --edit -e \
    --rename-section --remove-section --comment && return 1
  in_list "${pos[1]-}" get list && return 0
  has_flag --get --get-all --get-regexp --get-urlmatch --get-color \
    --get-colorbool --list -l && return 0
  # Legacy `git config <key>` is a read; `git config <key> <value>` writes.
  (( ${#pos[@]} == 1 )) && ! in_list "${pos[1]}" set unset rename-section remove-section edit
}

git_stash_ok()    { split_args "$@"; in_list "${pos[1]-}" list show; }
git_reflog_ok()   { split_args "$@"; ! in_list "${pos[1]-}" expire delete drop; }
git_worktree_ok() { split_args "$@"; [[ ${pos[1]-} == list ]]; }

git_notes_ok() {
  vopts=(--ref)
  split_args "$@"
  (( ! ${#pos[@]} )) || in_list "${pos[1]}" list show
}

git_submodule_ok() {
  split_args "$@"
  (( ! ${#pos[@]} )) || in_list "${pos[1]}" status summary
}

git_symbolic_ref_ok() {
  split_args "$@"
  flags_within -q --quiet --short --recurse --no-recurse && (( ${#pos[@]} <= 1 ))
}

# GIT_* variables that can't make git run another program or write.
git_env_ok() {
  local name=${1%%=*}
  [[ $name == GIT_* ]] || return 0
  case $name in
    GIT_AUTHOR_NAME|GIT_AUTHOR_EMAIL|GIT_AUTHOR_DATE) return 0 ;;
    GIT_COMMITTER_NAME|GIT_COMMITTER_EMAIL|GIT_COMMITTER_DATE) return 0 ;;
    GIT_DIR|GIT_WORK_TREE|GIT_TERMINAL_PROMPT|GIT_OPTIONAL_LOCKS) return 0 ;;
    GIT_TRACE*) return 0 ;;
  esac
  deny "setting \`$name\` can make git run other commands"
}

# --- git, sandboxed ------------------------------------------------------------

# Only write history, refs or the index, all of which live in .git where the
# sandbox guards real repos.
GIT_SANDBOXED=(
  add am bisect branch cherry-pick clone commit fetch gc init merge mv notes
  pull push rebase reflog remote revert submodule symbolic-ref tag
)

# Writes go to .git/config unless pointed at a config file outside .git.
sandboxed_git_config_ok() {
  vopts=(-f --file --blob --type --default)
  split_args "$@"
  ! has_flag --global --system -f --file --edit -e
}

# `git checkout <path>` discards changes and looks just like switching to a
# branch, so only allow the unambiguous branch-creating forms; use `switch`.
sandboxed_git_checkout_ok() {
  in_list -- "$@" && return 1
  vopts=(-b -B --orphan)
  split_args "$@"
  has_flag -b -B --orphan || return 1
  ! has_flag -f --force -p --patch --ours --theirs -m --merge --conflict \
    --pathspec-from-file && (( ${#pos[@]} <= 1 ))
}

sandboxed_git_switch_ok() { split_args "$@"; ! has_flag -f --force --discard-changes; }
sandboxed_git_reset_ok()  { split_args "$@"; ! has_flag --hard; }
sandboxed_git_rm_ok()     { split_args "$@"; expand_short; ! has_flag -f --force; }
sandboxed_git_stash_ok()  { split_args "$@"; ! in_list "${pos[1]-}" drop clear; }

# Unstaging only: `restore` without --staged, or with --worktree, overwrites files.
sandboxed_git_restore_ok() {
  vopts=(-s --source)
  split_args "$@"
  expand_short
  has_flag -S --staged && ! has_flag -W --worktree
}

sandboxed_git_worktree_ok() {
  split_args "$@"
  expand_short
  [[ ${pos[1]-} != remove ]] || ! has_flag -f --force
}

# Prints "enforced" only if every settings file Claude Code reads keeps the
# sandbox on and inescapable. Fails closed: a missing key, a file jq can't
# parse, or a source we can't read (MDM plists) all mean not enforced.
sandbox_probe() {
  setopt localoptions null_glob
  local cfg=${CLAUDE_CONFIG_DIR:-$HOME/.claude} f
  jq -e '.sandbox | .enabled == true and .allowUnsandboxedCommands == false
    and .failIfUnavailable == true
    and (.filesystem.denyWrite // [] | index("~/**/.git") != null)' \
    "$cfg/settings.json" >/dev/null 2>&1 || return
  [[ -e "/Library/Managed Preferences/com.anthropic.claudecode.plist" ]] && return
  for f in "$cfg"/settings.json "$cfg"/settings.local.json "$cfg"/remote-settings.json \
    "/Library/Application Support/ClaudeCode"/managed-settings.json \
    "/Library/Application Support/ClaudeCode"/managed-settings.d/*.json \
    /etc/claude-code/managed-settings.json /etc/claude-code/managed-settings.d/*.json \
    "${CLAUDE_PROJECT_DIR:-/nonexistent}"/.claude/settings.json \
    "${CLAUDE_PROJECT_DIR:-/nonexistent}"/.claude/settings.local.json; do
    [[ -e $f ]] || continue
    jq -e '.sandbox // {} | (.enabled == false or .allowUnsandboxedCommands == true
      or .failIfUnavailable == false or (.excludedCommands // [] | length > 0)) | not' \
      "$f" >/dev/null 2>&1 || return
  done
  print enforced
}

sandbox_state=""
sandbox_enforced() {
  [[ -n $sandbox_state ]] || sandbox_state=$(sandbox_probe) || sandbox_state=no
  [[ $sandbox_state == enforced ]]
}

check_git() {
  while (( $# )); do
    case $1 in
      -C|--git-dir|--work-tree|--namespace|--super-prefix) shift; (( $# )) && shift ;;
      # These can point git at arbitrary programs (core.pager, alias.x=!cmd, ...).
      -c*|--config-env*|--exec-path*)
        deny "\`git $1\` can override config to run arbitrary commands"; return ;;
      --version|--help|-h|-v) return 0 ;;
      -*) shift ;;
      *) break ;;
    esac
  done
  (( $# )) || return 0
  local sub=$1 a
  shift
  for a in "$@"; do
    case $a in
      --output|--output=*) deny "\`git $sub --output\` writes files"; return ;;
      # Each of these names a program for git to run.
      --upload-pack*|--receive-pack*|--exec|--exec=*|-O*|--open-files-in-pager*)
        deny "\`git $sub $a\` runs an arbitrary program"; return ;;
    esac
    case $sub:$a in
      clone:-u*|ls-remote:-u*|clone:-c*|clone:--config|clone:--config=*)
        deny "\`git $sub $a\` runs an arbitrary program"; return ;;
    esac
  done
  in_list "$sub" "${GIT_READ[@]}" && return 0
  local fn=git_${sub//-/_}_ok
  if typeset -f "$fn" >/dev/null && "$fn" "$@"; then return 0; fi
  if sandbox_enforced; then
    in_list "$sub" "${GIT_SANDBOXED[@]}" && return 0
    fn=sandboxed_$fn
    if typeset -f "$fn" >/dev/null && "$fn" "$@"; then return 0; fi
    deny "\`git $sub\` could discard uncommitted work"
    return
  fi
  deny "\`git $sub\` is not a read-only git command (and the Bash sandbox isn't enforced here)"
}

# --- gh ----------------------------------------------------------------------

# gh_read_ok <group> <verb>
gh_read_ok() {
  case $1 in
    search|status|help|version) return 0 ;;
    auth)     in_list "$2" status ;;
    cache)    in_list "$2" list ;;
    gist)     in_list "$2" list view ;;
    issue)    in_list "$2" list status view ;;
    label)    in_list "$2" list ;;
    org)      in_list "$2" list ;;
    pr)       in_list "$2" checks diff list status view ;;
    release)  in_list "$2" list view ;;
    repo)     in_list "$2" list view ;;
    ruleset)  in_list "$2" check list view ;;
    run)      in_list "$2" list view watch ;;
    secret)   in_list "$2" list ;;
    variable) in_list "$2" get list ;;
    workflow) in_list "$2" list view ;;
    *) return 1 ;;
  esac
}

check_gh_api() {
  local method="" endpoint="" sends_data=0
  while (( $# )); do
    case $1 in
      -X|--method) method=${2-}; shift; (( $# )) && shift; continue ;;
      --method=*) method=${1#*=} ;;
      -X?*) method=${1#-X} ;;
      -f|-F|--field|--raw-field|--input|--field=*|--raw-field=*|--input=*|-[fF]?*) sends_data=1 ;;
      -*) ;;
      *) [[ -z $endpoint ]] && endpoint=$1 ;;
    esac
    shift
  done
  [[ $endpoint == graphql ]] && { deny "\`gh api graphql\` can run mutations"; return; }
  if [[ -n $method ]]; then
    case $method in
      [Gg][Ee][Tt]) return 0 ;;
      *) deny "\`gh api -X $method\` is not read-only"; return ;;
    esac
  fi
  (( ! sends_data )) || deny "\`gh api\` with fields defaults to POST; pass \`-X GET\` for reads"
}

check_gh() {
  local -a words
  local a
  local -i skip=0
  while (( $# )); do
    a=$1
    shift
    if (( skip )); then skip=0; continue; fi
    case $a in
      -R|--repo|--hostname) skip=1 ;;
      --version|--help|-h) (( ${#words[@]} )) || return 0 ;;
      -*) ;;
      *)
        words+=("$a")
        if [[ ${#words[@]} == 1 && $a == api ]]; then check_gh_api "$@"; return; fi
        (( ${#words[@]} == 2 )) && break
        ;;
    esac
  done
  (( ${#words[@]} )) || return 0
  gh_read_ok "${words[1]}" "${words[2]-}" && return 0
  deny "\`gh ${words[*]}\` is not a read-only gh command"
}

# --- shell parsing -----------------------------------------------------------

# Commands/keywords that run the word after them (plus their own options).
WRAPPERS=(builtin command env exec nice nohup sudo time timeout xargs doas
  '!' '{' 'if' 'then' 'else' 'elif' 'do' 'while' 'until')
WRAPPER_VALUE_OPTS=(-I -n -P -L -s -d -E -u -g -k)
SHELLS=(sh bash zsh dash ksh fish)

check_words() {
  while (( $# )) && [[ $1 == [A-Za-z_][A-Za-z0-9_]#=* ]]; do
    git_env_ok "$1" || return
    shift
  done
  while (( $# )) && in_list "${1##*/}" "${WRAPPERS[@]}"; do
    shift
    while (( $# )) && [[ $1 == -* || $1 == [A-Za-z_][A-Za-z0-9_]#=* || $1 == [0-9.]##[smhd]# ]]; do
      [[ $1 == -* ]] || git_env_ok "$1" || return
      if in_list "$1" "${WRAPPER_VALUE_OPTS[@]}" && (( $# > 1 )); then shift; fi
      shift
    done
  done
  (( $# )) || return 0
  local cmd=${1##*/}
  shift

  local a
  case $cmd in
    git)  check_git "$@"; return ;;
    gh)   check_gh "$@"; return ;;
    eval) check_command "$*"; return ;;
    export|typeset|declare|local|readonly|setenv)
      for a in "$@"; do git_env_ok "$a" || return; done
      return 0
      ;;
  esac
  if in_list "$cmd" "${SHELLS[@]}"; then
    while (( $# > 1 )); do
      a=$1
      shift
      [[ $a == -[A-Za-z]#c[A-Za-z]# ]] && { check_command "$1"; return; }
    done
    return 0
  fi
  while (( $# )); do
    a=$1
    shift
    if in_list "$a" -exec -execdir -ok -okdir; then
      check_words "$@" || return
    fi
  done
  return 0
}

check_command() {
  local -a toks segment
  # shellcheck disable=SC2296 # zsh (z) flag: split using the shell's parser
  toks=("${(z)1}")
  local tok val sub
  local -i skip_next=0
  for tok in "${toks[@]}" ';'; do
    if (( skip_next )); then skip_next=0; continue; fi
    case $tok in
      '&&'|'||'|'|'|'|&'|'&'|'&|'|'&!'|';'|';;'|'('|')'|'(('|'))')
        check_words "${segment[@]}" || return
        segment=()
        ;;
      [0-9]#[\<\>\&\|]##)
        # Redirect operator: drop the target that follows it.
        [[ $tok == *[\<\>]* ]] && skip_next=1
        ;;
      *)
        # shellcheck disable=SC2296 # zsh (Q) flag: remove one level of quoting
        val=${(Q)tok}
        # Check $(...), <(...) and backtick contents as commands of their own.
        if [[ $val == *"\$("* || $val == *'<('* || $val == *'>('* || $val == *'`'* ]]; then
          sub=${val//"\$("/ ; }
          sub=${sub//'<('/ ; }
          sub=${sub//'>('/ ; }
          sub=${sub//'`'/ ; }
          sub=${sub//')'/ ; }
          check_command "$sub" || return
        fi
        segment+=("$val")
        ;;
    esac
  done
  return 0
}

cmdline=$(jq -r '.tool_input.command // ""')
if ! check_command "$cmdline"; then
  jq -n --arg r "Blocked: $reason. The user only permits read-only git/gh commands; ask them to run this themselves." \
    '{hookSpecificOutput: {hookEventName: "PreToolUse", permissionDecision: "deny", permissionDecisionReason: $r}}'
fi
exit 0
