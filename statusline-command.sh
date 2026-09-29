#!/bin/bash
# Claude Code status line: model + dir, then colored bars for context, 5h and weekly rate limits, plus cache warmth.

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

# token count -> "45.2k"
fmt_tokens() {
  awk -v n="$1" 'BEGIN { if (n >= 1000) printf "%.1fk", n / 1000; else printf "%d", n }'
}

# Estimate prompt-cache warmth from the last main-thread API call in the transcript.
cache_status() {
  local tp=$1
  if [ -z "$tp" ] || [ ! -f "$tp" ]; then return; fi

  # -> "<called_at epoch>\t<ttl>\t<cache read tokens>\t<total input tokens>"
  local info
  info=$(tail -c 524288 "$tp" | jq -Rrn '
    [inputs | fromjson? | select(type == "object" and .type == "assistant"
      and (.isSidechain | not) and .message.usage)]
    | if length == 0 then empty else
        .[-1] as $last
        | ([reverse[] | .message.usage.cache_creation // {}
            | if (.ephemeral_1h_input_tokens // 0) > 0 then 3600
              elif (.ephemeral_5m_input_tokens // 0) > 0 then 300
              else empty end] | first // 300) as $ttl
        | $last.message.usage as $u
        | [($last.timestamp | sub("\\.[0-9]+"; "") | fromdateiso8601), $ttl,
           ($u.cache_read_input_tokens // 0),
           (($u.cache_read_input_tokens // 0) + ($u.cache_creation_input_tokens // 0) + ($u.input_tokens // 0))]
        | @tsv
      end' 2>/dev/null)
  info=${info//$'\r'/}
  [ -z "$info" ] && return

  local called ttl read total
  IFS=$'\t' read -r called ttl read total <<< "$info"
  local remaining=$(( called + ttl - $(date +%s) ))

  local hit="" label="5m"
  [ "$total" -gt 0 ] && printf -v hit ' %b%d%% hit%b' "$GRAY" $(( read * 100 / total )) "$RESET"
  [ "$ttl" -eq 3600 ] && label="1h"

  if [ "$remaining" -le 0 ]; then
    printf 'Cache %b● cold%b %b(%s)%b%s' "$RED" "$RESET" "$GRAY" "$label" "$RESET" "$hit"
    return
  fi
  local color=$YELLOW left
  [ $(( remaining * 5 )) -gt "$ttl" ] && color=$GREEN
  local m=$(( remaining / 60 )) s=$(( remaining % 60 ))
  if [ "$m" -lt 10 ]; then printf -v left '%dm%02ds' "$m" "$s"; else left="${m}m"; fi
  printf 'Cache %b● %s left%b %b(%s)%b%s' "$color" "$left" "$RESET" "$GRAY" "$label" "$RESET" "$hit"
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
ctx_used=$(echo "$input" | jq -r '.context_window.total_input_tokens // 0')
ctx_size=$(echo "$input" | jq -r '.context_window.context_window_size // 0')
if [ "${ctx_used%.*}" -gt 0 ] 2>/dev/null && [ "${ctx_size%.*}" -gt 0 ] 2>/dev/null; then
  line2="$line2 ($(fmt_tokens "$ctx_used")/$(fmt_tokens "$ctx_size"))"
fi

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

# --- prompt cache ---
cache=$(cache_status "$(echo "$input" | jq -r '.transcript_path // empty')")
[ -n "$cache" ] && line2="$line2  |  $cache"

printf '%s\n%s' "$line1" "$line2"
