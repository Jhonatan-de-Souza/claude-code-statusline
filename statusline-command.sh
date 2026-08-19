#!/bin/bash
# Claude Code status line: model + dir, then colored bars for context, 5h and weekly rate limits.

input=$(cat)

GREEN='\033[32m'; YELLOW='\033[33m'; RED='\033[31m'; CYAN='\033[36m'; GRAY='\033[2m'; RESET='\033[0m'
BAR_WIDTH=10

# pick ANSI color by usage threshold
color_for() {
  local pct=$1
  if [ "$pct" -ge 90 ]; then printf '%b' "$RED"
  elif [ "$pct" -ge 70 ]; then printf '%b' "$YELLOW"
  else printf '%b' "$GREEN"
  fi
}

# render a colored block bar for an integer percentage
bar() {
  local pct=$1 color=$2
  [ "$pct" -gt 100 ] && pct=100
  local filled=$(( pct * BAR_WIDTH / 100 ))
  local empty=$(( BAR_WIDTH - filled ))
  local f="" e=""
  [ "$filled" -gt 0 ] && printf -v f "%${filled}s" && f="${f// /█}"
  [ "$empty" -gt 0 ] && printf -v e "%${empty}s" && e="${e// /░}"
  printf '%b%s%b%s%b' "$color" "$f" "$GRAY" "$e" "$RESET"
}

# colored "NN%" text using the same threshold color as the bar
pct_text() {
  local pct=$1 color=$2
  printf '%b%s%%%b' "$color" "$pct" "$RESET"
}

# Unix seconds -> "2h14m" until reset
fmt_reset() {
  local ts=$1
  [ -z "$ts" ] && { printf -- '--'; return; }
  local now diff h m
  now=$(date +%s)
  diff=$(( ts - now ))
  [ "$diff" -lt 0 ] && diff=0
  h=$(( diff / 3600 ))
  m=$(( (diff % 3600) / 60 ))
  printf '%dh%02dm' "$h" "$m"
}

model=$(echo "$input" | jq -r '.model.display_name')
dir=$(echo "$input" | jq -r '.workspace.current_dir')
branch=""
if git -C "$dir" rev-parse --git-dir > /dev/null 2>&1; then
  branch=$(git -C "$dir" branch --show-current 2>/dev/null)
fi

line1=$(printf '%b[%s]%b 📁 %s' "$CYAN" "$model" "$RESET" "${dir##*/}")
[ -n "$branch" ] && line1="$line1 | 🌿 $branch"

# --- context window ---
ctx=$(echo "$input" | jq -r '.context_window.used_percentage // 0' | cut -d. -f1)
[ -z "$ctx" ] && ctx=0
ctx_color=$(color_for "$ctx")
line2="Ctx $(bar "$ctx" "$ctx_color") $(pct_text "$ctx" "$ctx_color")"

# --- 5-hour rate limit ---
five=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
if [ -n "$five" ]; then
  five_reset=$(echo "$input" | jq -r '.rate_limits.five_hour.resets_at // empty')
  five_i=${five%.*}; [ -z "$five_i" ] && five_i=0
  five_color=$(color_for "$five_i")
  line2="$line2  |  5h $(bar "$five_i" "$five_color") $(pct_text "$five_i" "$five_color") (resets $(fmt_reset "$five_reset"))"
fi

# --- weekly rate limit ---
week=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')
if [ -n "$week" ]; then
  week_reset=$(echo "$input" | jq -r '.rate_limits.seven_day.resets_at // empty')
  week_i=${week%.*}; [ -z "$week_i" ] && week_i=0
  week_color=$(color_for "$week_i")
  line2="$line2  |  7d $(bar "$week_i" "$week_color") $(pct_text "$week_i" "$week_color") (resets $(fmt_reset "$week_reset"))"
fi

printf '%s\n%s' "$line1" "$line2"
