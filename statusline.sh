#!/usr/bin/env bash
# Claude Code statusLine — usage monitor with Anthropic brand gradient
# https://github.com/laiyanlong/claude-code-usage-statusline
#
# Reads the JSON Claude Code passes on stdin and prints a single status line
# containing: cwd, git branch, model, 5h / 7d rate-limit bars, context bar.

input=$(cat)

# ── helpers ────────────────────────────────────────────────────────────────
jq_val() { echo "$input" | jq -r "$1 // empty"; }

SEP=$(printf " \033[38;5;95m│\033[0m ")   # warm grey-brown │ (#875F5F)

# ── 1. Directory + git ─────────────────────────────────────────────────────
cwd=$(jq_val '.workspace.current_dir // .cwd')
display_path="${cwd/#$HOME/~}"
dir_part=$(printf "\033[1;34m%s\033[0m" "$display_path")

git_part=""
if git -C "$cwd" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  branch=$(git -C "$cwd" --no-optional-locks symbolic-ref --short HEAD 2>/dev/null \
           || git -C "$cwd" --no-optional-locks rev-parse --short HEAD 2>/dev/null)
  dirty=$(git -C "$cwd" --no-optional-locks status --porcelain 2>/dev/null | head -1)
  if [ -n "$dirty" ]; then
    git_part=$(printf " \033[34mgit:(\033[31m%s\033[34m)\033[33m *\033[0m" "$branch")
  else
    git_part=$(printf " \033[34mgit:(\033[31m%s\033[34m)\033[0m" "$branch")
  fi
fi

# ── 2. Model ───────────────────────────────────────────────────────────────
model_name=$(jq_val '.model.display_name')
model_short="${model_name#Claude }"
model_part=""
[ -n "$model_short" ] && model_part=$(printf "\033[38;5;173m%s\033[0m" "$model_short")

# ── 3. Helpers ─────────────────────────────────────────────────────────────

# $1 = resets_at (unix epoch); prints e.g. "2h14m" or "3d05h"
format_countdown() {
  local resets_at="$1"
  [ -z "$resets_at" ] && return
  local now
  now=$(date +%s)
  local secs=$(( resets_at - now ))
  [ "$secs" -le 0 ] && { printf "now"; return; }
  local days=$(( secs / 86400 ))
  local hours=$(( (secs % 86400) / 3600 ))
  local mins=$(( (secs % 3600) / 60 ))
  if [ "$days" -gt 0 ]; then
    printf "%dd%02dh" "$days" "$hours"
  elif [ "$hours" -gt 0 ]; then
    printf "%dh%02dm" "$hours" "$mins"
  else
    printf "%dm" "$mins"
  fi
}

# Anthropic / Claude warm gradient (dark-theme optimised):
#   0 – 25%  light apricot   223 #FFD7AF
#   25 – 45% sand orange     216 #FFAF87
#   45 – 65% Claude orange   173 #D7875F ≈ #D97757
#   65 – 85% deep terracotta 166 #D75F00
#   85 –100% dark crimson    124 #AF0000
cell_color() {
  local idx="$1" width="$2"
  local pos=$(( (idx * 100 + 50) / width ))
  if   [ "$pos" -lt 25 ]; then printf "223"
  elif [ "$pos" -lt 45 ]; then printf "216"
  elif [ "$pos" -lt 65 ]; then printf "173"
  elif [ "$pos" -lt 85 ]; then printf "166"
  else                          printf "124"
  fi
}

make_bar() {
  local pct="$1"
  local width="${2:-16}"
  [ "$pct" -gt 100 ] && pct=100

  local total_halves=$(( width * 2 ))
  local filled_halves=$(( pct * total_halves / 100 ))
  local full_blocks=$(( filled_halves / 2 ))
  local half_block=$(( filled_halves % 2 ))
  local empty_blocks=$(( width - full_blocks - half_block ))

  local bar="" i col
  for (( i=0; i<full_blocks; i++ )); do
    col=$(cell_color "$i" "$width")
    bar="${bar}$(printf "\033[38;5;%sm█\033[0m" "$col")"
  done
  if [ "$half_block" -eq 1 ]; then
    col=$(cell_color "$full_blocks" "$width")
    bar="${bar}$(printf "\033[38;5;%sm▌\033[0m" "$col")"
  fi
  for (( i=0; i<empty_blocks; i++ )); do
    bar="${bar}$(printf "\033[2;37m░\033[0m")"
  done

  printf "%s" "$bar"
}

pct_color() {
  local pct="$1"
  if   [ "$pct" -ge 85 ]; then printf "124"
  elif [ "$pct" -ge 65 ]; then printf "166"
  elif [ "$pct" -ge 45 ]; then printf "173"
  elif [ "$pct" -ge 25 ]; then printf "216"
  else                          printf "223"
  fi
}

make_meter() {
  local label="$1" pct="$2" suffix="$4"
  local bar col
  bar=$(make_bar "$pct")
  col=$(pct_color "$pct")
  printf "\033[38;5;%sm%s [\033[0m%s\033[38;5;%sm] %3d%%%s\033[0m" \
    "$col" "$label" "$bar" "$col" "$pct" "$suffix"
}

# ── 4. 5-hour rate limit ───────────────────────────────────────────────────
five_pct=$(jq_val '.rate_limits.five_hour.used_percentage')
five_resets=$(jq_val '.rate_limits.five_hour.resets_at')
five_part=""
if [ -n "$five_pct" ]; then
  five_int=${five_pct%.*}
  timer=""
  cd_val=$(format_countdown "$five_resets")
  [ -n "$cd_val" ] && timer=$(printf " \xE2\x8F\xB0%s" "$cd_val")
  five_part=$(make_meter "5h" "$five_int" "" "$timer")
fi

# ── 5. 7-day rate limit ────────────────────────────────────────────────────
seven_pct=$(jq_val '.rate_limits.seven_day.used_percentage')
seven_resets=$(jq_val '.rate_limits.seven_day.resets_at')
seven_part=""
if [ -n "$seven_pct" ]; then
  seven_int=${seven_pct%.*}
  timer=""
  cd_val=$(format_countdown "$seven_resets")
  [ -n "$cd_val" ] && timer=$(printf " \xE2\x8F\xB0%s" "$cd_val")
  seven_part=$(make_meter "7d" "$seven_int" "" "$timer")
fi

# ── 6. Context window ──────────────────────────────────────────────────────
ctx_used=$(jq_val '.context_window.used_percentage')
ctx_part=""
if [ -n "$ctx_used" ]; then
  ctx_int=${ctx_used%.*}
  ctx_part=$(make_meter "ctx" "$ctx_int" "" "")
fi

# ── Assemble ───────────────────────────────────────────────────────────────
line="${dir_part}${git_part}"
for part in "$model_part" "$five_part" "$seven_part" "$ctx_part"; do
  [ -n "$part" ] && line="${line}${SEP}${part}"
done

printf "%s" "$line"
