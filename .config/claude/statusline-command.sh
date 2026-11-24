#!/usr/bin/env bash
# Claude Code statusline — Powerlevel10k lean colors (nerdfont-v3)
#   project:         256-color 39 bold (subdir: 31)
#   vcs clean:       256-color 76  (green)
#   vcs modified:    256-color 178 (yellow)
#   vcs untracked:   256-color 39  (blue)
#   vcs conflicted:  256-color 196 (red)
#   session info:    256-color 244 (grey), separators 240

c() { printf '\033[38;5;%sm' "$1"; }   # set 256-color foreground
bold=$'\033[1m'
reset=$'\033[0m'
sep=" $(c 240)│ "
# Emojis are single codepoints only: variation-selector ones (✏️, ⚠️) mis-measure in terminals

# ── Session JSON: one jq call; fields missing in older versions come back empty
IFS=$'\x1f' read -r cwd project model ctx cost added removed < <(
  jq -r '[
    (.cwd // .workspace.current_dir // ""),
    (.workspace.project_dir // ""),
    (.model.display_name // ""),
    (.context_window.used_percentage // "" | tostring),
    (.cost.total_cost_usd // "" | tostring),
    (.cost.total_lines_added // 0 | tostring),
    (.cost.total_lines_removed // 0 | tostring)
  ] | join("\u001f")'
)

# ── Directory: project name, plus the subdirectory when Claude has cd'd deeper
project=${project:-$cwd}
dir="📂 ${bold}$(c 39)${project##*/}${reset}"
if [[ "$cwd" == "$project/"* ]]; then
  dir+="$(c 31)/${cwd#"$project/"}"
fi

# ── Git: one status call; --no-optional-locks avoids fighting Claude's own git use
git_part=""
if status=$(git --no-optional-locks -C "$cwd" status --porcelain=v2 --branch 2>/dev/null); then
  read -r branch ahead behind staged unstaged untracked conflicted < <(
    awk '
      /^# branch\.head /  { head = $3 }
      /^# branch\.oid /   { oid = substr($3, 1, 7) }
      /^# branch\.ab /    { a = substr($3, 2); b = substr($4, 2) }
      /^[12] /            { if (substr($2, 1, 1) != ".") s++; if (substr($2, 2, 1) != ".") m++ }
      /^u /               { u++ }
      /^\? /              { q++ }
      END {
        if (head == "(detached)") head = oid
        printf "%s %d %d %d %d %d %d\n", head, a, b, s, m, q, u
      }
    ' <<< "$status"
  )

  if (( conflicted )); then vcs_color=196; mood=" 💥"
  elif (( staged || unstaged )); then vcs_color=178; mood=" 🚧"
  elif (( untracked )); then vcs_color=39; mood=" 🌱"
  else vcs_color=76; mood=" ✨"
  fi

  counts=""
  (( behind ))     && counts+=" ⇣${behind}"
  (( ahead ))      && counts+=" ⇡${ahead}"
  (( conflicted )) && counts+=" ~${conflicted}"
  (( staged ))     && counts+=" +${staged}"
  (( unstaged ))   && counts+=" !${unstaged}"
  (( untracked ))  && counts+=" ?${untracked}"

  git_part=" 🌿 $(c "$vcs_color")${branch}${counts}${mood}"
fi

# ── Session info ─────────────────────────────────────────────────────────────
info=""
if [[ -n "$model" ]]; then
  case "$model" in   # macOS bash 3.2: no ${var,,}, so match both cases
    *[Oo]pus*)     model_icon="🎼" ;;
    *[Ss]onnet*)   model_icon="📜" ;;
    *[Hh]aiku*)    model_icon="🌸" ;;
    *[Ff]able*)    model_icon="📖" ;;
    *)        model_icon="🤖" ;;
  esac
  info+="${sep}${model_icon} $(c 244)${model}"
fi

# Brain heats up as the context window fills toward compaction
if [[ -n "$ctx" ]]; then
  pct=${ctx%.*}
  if (( pct >= 80 )); then ctx_color=196; ctx_icon="🔥"
  elif (( pct >= 50 )); then ctx_color=178; ctx_icon="🥵"
  else ctx_color=244; ctx_icon="🧠"
  fi
  info+="${sep}${ctx_icon} $(c "$ctx_color")${pct}%"
fi

[[ -n "$cost" ]] && info+="${sep}💸 $(c 244)$(printf '$%.2f' "$cost")"

if (( added || removed )); then
  info+="${sep}📝 $(c 76)+${added} $(c 196)−${removed}"
fi

printf '%s\n' "${dir}${git_part}${info}${reset}"
