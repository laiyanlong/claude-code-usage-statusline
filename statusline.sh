#!/usr/bin/env bash
# Claude Code statusLine — usage monitor with Anthropic brand gradient
# https://github.com/laiyanlong/claude-code-usage-statusline
#
# Reads the JSON Claude Code passes on stdin and prints a single status line:
#   cwd · git · model · 5h bar · 7d bar · ctx bar
#
# ── Customisation (environment variables) ──────────────────────────────────
#
#   STATUSLINE_BAR_WIDTH    integer, default 16          # 8 / 16 / 24 / 32
#   STATUSLINE_THEME        warm (default) | classic | neon | mono
#   STATUSLINE_PULSE        0 (off) | 1 (blink danger ≥85%) | 2 (wave anim)
#   STATUSLINE_HIDE         comma list: 5h, 7d, ctx, model, git, path
#   STATUSLINE_HALF_BLOCK   default ▌  (try ▎ for ¼, ▊ for ¾)
#   STATUSLINE_SEP          default │   (try •  ▸  ⋯)
#
# Example: STATUSLINE_PULSE=1 STATUSLINE_BAR_WIDTH=24 bash statusline.sh
# ───────────────────────────────────────────────────────────────────────────

input=$(cat)

# ── Config ────────────────────────────────────────────────────────────────
BAR_WIDTH="${STATUSLINE_BAR_WIDTH:-16}"
THEME="${STATUSLINE_THEME:-warm}"
PULSE="${STATUSLINE_PULSE:-0}"
HIDE="${STATUSLINE_HIDE:-}"
HALF="${STATUSLINE_HALF_BLOCK:-▌}"
SEP_CHAR="${STATUSLINE_SEP:-│}"

is_hidden() { case ",$HIDE," in *",$1,"*) return 0;; *) return 1;; esac; }

# ── Theme palettes (low → high gradient stops) ────────────────────────────
case "$THEME" in
  warm)    C0=223; C1=216; C2=173; C3=166; C4=124; ACCENT=173 ;;  # apricot → crimson
  classic) C0=46;  C1=226; C2=208; C3=202; C4=196; ACCENT=33  ;;  # green  → red
  neon)    C0=51;  C1=87;  C2=201; C3=165; C4=93;  ACCENT=87  ;;  # cyan   → magenta
  mono)    C0=255; C1=250; C2=244; C3=240; C4=235; ACCENT=255 ;;  # white  → grey
  *)       C0=223; C1=216; C2=173; C3=166; C4=124; ACCENT=173 ;;
esac

jq_val() { echo "$input" | jq -r "$1 // empty"; }

SEP=$(printf " \033[38;5;95m%s\033[0m " "$SEP_CHAR")

# ── 1. Directory + git ─────────────────────────────────────────────────────
cwd=$(jq_val '.workspace.current_dir // .cwd')
display_path="${cwd/#$HOME/~}"
dir_part=""
is_hidden path || dir_part=$(printf "\033[1;34m%s\033[0m" "$display_path")

git_part=""
if ! is_hidden git && git -C "$cwd" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
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
if ! is_hidden model && [ -n "$model_short" ]; then
  model_part=$(printf "\033[38;5;%dm%s\033[0m" "$ACCENT" "$model_short")
fi

# ── 3. Helpers ─────────────────────────────────────────────────────────────

# $1 = unix epoch resets_at; prints "2h14m" or "3d05h" or "now"
format_countdown() {
  local resets_at="$1"
  [ -z "$resets_at" ] && return
  local now; now=$(date +%s)
  local secs=$(( resets_at - now ))
  [ "$secs" -le 0 ] && { printf "now"; return; }
  local days=$(( secs / 86400 ))
  local hours=$(( (secs % 86400) / 3600 ))
  local mins=$(( (secs % 3600) / 60 ))
  if   [ "$days" -gt 0 ];  then printf "%dd%02dh" "$days" "$hours"
  elif [ "$hours" -gt 0 ]; then printf "%dh%02dm" "$hours" "$mins"
  else                          printf "%dm" "$mins"; fi
}

# Cell colour by position within the bar (0-based idx, total width).
cell_color() {
  local idx="$1" width="$2"
  local pos=$(( (idx * 100 + 50) / width ))
  if   [ "$pos" -lt 25 ]; then printf "%d" "$C0"
  elif [ "$pos" -lt 45 ]; then printf "%d" "$C1"
  elif [ "$pos" -lt 65 ]; then printf "%d" "$C2"
  elif [ "$pos" -lt 85 ]; then printf "%d" "$C3"
  else                          printf "%d" "$C4"; fi
}

# Render one bar: $1=pct, $2=width
make_bar() {
  local pct="$1" width="${2:-$BAR_WIDTH}"
  [ "$pct" -gt 100 ] && pct=100

  local total_halves=$(( width * 2 ))
  local filled_halves=$(( pct * total_halves / 100 ))
  local full_blocks=$(( filled_halves / 2 ))
  local half_block=$(( filled_halves % 2 ))
  local empty_blocks=$(( width - full_blocks - half_block ))

  # Animation: PULSE=1 → blink danger cells (pct ≥ 85)
  #            PULSE=2 → wave: brighten one cell that walks left→right per second
  local danger_blink=""
  [ "$PULSE" = "1" ] && [ "$pct" -ge 85 ] && danger_blink="\033[5m"

  local wave_idx=-1
  if [ "$PULSE" = "2" ] && [ "$full_blocks" -gt 0 ]; then
    wave_idx=$(( $(date +%s) % full_blocks ))
  fi

  local bar="" i col
  for (( i=0; i<full_blocks; i++ )); do
    col=$(cell_color "$i" "$width")
    if [ "$i" -eq "$wave_idx" ]; then
      bar="${bar}$(printf "\033[1;38;5;%sm█\033[0m" "$col")"   # bright
    elif [ "$i" -ge $(( full_blocks - 1 )) ] && [ -n "$danger_blink" ]; then
      bar="${bar}$(printf "${danger_blink}\033[38;5;%sm█\033[0m" "$col")"
    else
      bar="${bar}$(printf "\033[38;5;%sm█\033[0m" "$col")"
    fi
  done
  if [ "$half_block" -eq 1 ]; then
    col=$(cell_color "$full_blocks" "$width")
    bar="${bar}$(printf "\033[38;5;%sm%s\033[0m" "$col" "$HALF")"
  fi
  for (( i=0; i<empty_blocks; i++ )); do
    bar="${bar}$(printf "\033[2;37m░\033[0m")"
  done

  printf "%s" "$bar"
}

pct_color() {
  local pct="$1"
  if   [ "$pct" -ge 85 ]; then printf "%d" "$C4"
  elif [ "$pct" -ge 65 ]; then printf "%d" "$C3"
  elif [ "$pct" -ge 45 ]; then printf "%d" "$C2"
  elif [ "$pct" -ge 25 ]; then printf "%d" "$C1"
  else                          printf "%d" "$C0"; fi
}

make_meter() {
  local label="$1" pct="$2" suffix="$4"
  local bar col
  bar=$(make_bar "$pct")
  col=$(pct_color "$pct")
  printf "\033[38;5;%dm%s [\033[0m%s\033[38;5;%dm] %3d%%%s\033[0m" \
    "$col" "$label" "$bar" "$col" "$pct" "$suffix"
}

# ── 4. 5-hour rate limit ───────────────────────────────────────────────────
five_part=""
if ! is_hidden 5h; then
  five_pct=$(jq_val '.rate_limits.five_hour.used_percentage')
  five_resets=$(jq_val '.rate_limits.five_hour.resets_at')
  if [ -n "$five_pct" ]; then
    five_int=${five_pct%.*}
    timer=""
    cd_val=$(format_countdown "$five_resets")
    [ -n "$cd_val" ] && timer=$(printf " \xE2\x8F\xB0%s" "$cd_val")
    five_part=$(make_meter "5h" "$five_int" "" "$timer")
  fi
fi

# ── 5. 7-day rate limit ────────────────────────────────────────────────────
seven_part=""
if ! is_hidden 7d; then
  seven_pct=$(jq_val '.rate_limits.seven_day.used_percentage')
  seven_resets=$(jq_val '.rate_limits.seven_day.resets_at')
  if [ -n "$seven_pct" ]; then
    seven_int=${seven_pct%.*}
    timer=""
    cd_val=$(format_countdown "$seven_resets")
    [ -n "$cd_val" ] && timer=$(printf " \xE2\x8F\xB0%s" "$cd_val")
    seven_part=$(make_meter "7d" "$seven_int" "" "$timer")
  fi
fi

# ── 6. Context window ──────────────────────────────────────────────────────
ctx_part=""
if ! is_hidden ctx; then
  ctx_used=$(jq_val '.context_window.used_percentage')
  if [ -n "$ctx_used" ]; then
    ctx_int=${ctx_used%.*}
    ctx_part=$(make_meter "ctx" "$ctx_int" "" "")
  fi
fi

# ── Assemble ───────────────────────────────────────────────────────────────
line="${dir_part}${git_part}"
for part in "$model_part" "$five_part" "$seven_part" "$ctx_part"; do
  [ -n "$part" ] && line="${line}${SEP}${part}"
done

printf "%s" "$line"
