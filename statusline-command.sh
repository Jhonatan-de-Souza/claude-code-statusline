#!/bin/bash
# Claude Code status line: model + dir + branch, then context, 5h/7d rate limits and prompt-cache warmth.
# Output fits the terminal width (COLUMNS): segments wrap onto new lines, and details drop only when wrapping is not enough.

input=$(cat)

GREEN='\033[32m'; YELLOW='\033[33m'; RED='\033[31m'; CYAN='\033[36m'; BOLD='\033[1m'; RESET='\033[0m'
# 256-color grays instead of "dim" (\033[2m), which is too faint in many themes.
GRAY='\033[38;5;244m'   # secondary text
TRACK='\033[38;5;238m'  # empty part of a bar
BAR_WIDTH=10
# Claude Code pads the status line a little; leave room so it never wraps.
MARGIN=4
width=$(( ${COLUMNS:-120} - MARGIN ))
now=$(date +%s)

# pick ANSI color by usage threshold
color_for() {
  if [ "$1" -ge 90 ]; then printf '%s' "$RED"
  elif [ "$1" -ge 70 ]; then printf '%s' "$YELLOW"
  else printf '%s' "$GREEN"
  fi
}

# render a colored block bar for an integer percentage
bar() {
  local pct=$1 color=$2 f="" e=""
  [ "$pct" -gt 100 ] && pct=100
  local filled=$(( pct * BAR_WIDTH / 100 ))
  local empty=$(( BAR_WIDTH - filled ))
  [ "$filled" -gt 0 ] && printf -v f "%${filled}s" && f="${f// /█}"
  [ "$empty" -gt 0 ] && printf -v e "%${empty}s" && e="${e// /░}"
  printf '%s%s%s%s%s' "$color" "$f" "$TRACK" "$e" "$RESET"
}

# bold colored number
num() { printf '%s%s%s%s' "$BOLD" "$2" "$1" "$RESET"; }

# token count -> "73k" / "1.2M"
fmt_tokens() {
  awk -v n="$1" 'BEGIN {
    if (n >= 1000000) { s = sprintf("%.1fM", n / 1000000); sub(/\.0M$/, "M", s); printf "%s", s }
    else if (n >= 1000) printf "%dk", int(n / 1000 + 0.5)
    else printf "%d", n }'
}

# seconds -> short countdown: 45s, 12m, 4h38m, 5d18h
fmt_duration() {
  local s=$1 m h d
  [ "$s" -lt 0 ] && s=0
  if [ "$s" -lt 60 ]; then printf '%ds' "$s"; return; fi
  m=$(( s / 60 ))
  if [ "$m" -lt 60 ]; then printf '%dm' "$m"; return; fi
  h=$(( m / 60 )); m=$(( m % 60 ))
  if [ "$h" -lt 24 ]; then printf '%dh%02dm' "$h" "$m"; return; fi
  d=$(( h / 24 )); h=$(( h % 24 ))
  printf '%dd%02dh' "$d" "$h"
}

# on-screen width: strip ANSI codes and count each UTF-8 char (█, │, ·) once, whatever the locale
visible_len() {
  local plain
  plain=$(printf '%b' "$1" | LC_ALL=C sed 's/\x1b\[[0-9;]*m//g; s/[\xc0-\xff][\x80-\xbf]*/x/g')
  printf '%d' "${#plain}"
}

truncate() {
  local text=$1 n=$2
  if [ "$(visible_len "$text")" -le "$n" ]; then printf '%s' "$text"; else printf '%s…' "${text:0:$(( n - 1 ))}"; fi
}

# Fallback for Claude Code < 2.1.251, which doesn't send `prompt_cache`.
# Estimates warmth from the last main-thread API call in the transcript.
# -> "<warm true|false>\t<ttl 5m|1h>\t<expires_at epoch>"
cache_from_transcript() {
  local tp=$1
  if [ -z "$tp" ] || [ ! -f "$tp" ]; then return; fi
  # The most recent cache write tells us the TTL. When a request mixes TTLs,
  # the 5m entries sit at the end (the conversation tail), so the bulk of the
  # prefix goes cold after 5 minutes: the short TTL wins.
  tail -c 524288 "$tp" | jq -Rrn --argjson now "$now" '
    [inputs | fromjson? | select(type == "object" and .type == "assistant"
      and (.isSidechain | not) and .message.usage)]
    | if length == 0 then empty else
        ([reverse[] | .message.usage.cache_creation // {}
          | if (.ephemeral_5m_input_tokens // 0) > 0 then "5m"
            elif (.ephemeral_1h_input_tokens // 0) > 0 then "1h"
            else empty end] | first // "5m") as $ttl
        | (.[-1].timestamp | sub("\\.[0-9]+"; "") | fromdateiso8601)
          + (if $ttl == "1h" then 3600 else 300 end) as $exp
        | [($exp > $now), $ttl, $exp] | @tsv
      end' 2>/dev/null | tr -d '\r'
}

# One jq pass for every field we need. Fields are split on \x1f, not tabs,
# because `read` collapses runs of whitespace and would drop empty fields.
IFS=$'\x1f' read -r model cwd ctx ctx_used ctx_size five five_reset week week_reset \
  pc_present pc_observed pc_warm pc_ttl pc_exp pc_recache transcript <<< "$(
  echo "$input" | jq -r '[
    (.model.display_name // "?"), (.workspace.current_dir // ""),
    ((.context_window.used_percentage // 0) | floor), (.context_window.total_input_tokens // 0),
    (.context_window.context_window_size // 0),
    (.rate_limits.five_hour.used_percentage // "" | if . == "" then . else floor end),
    (.rate_limits.five_hour.resets_at // ""),
    (.rate_limits.seven_day.used_percentage // "" | if . == "" then . else floor end),
    (.rate_limits.seven_day.resets_at // ""),
    (.prompt_cache != null), (.prompt_cache.caching_observed // true), (.prompt_cache.warm // false),
    (.prompt_cache.ttl // "5m"), (.prompt_cache.expires_at // 0),
    (.prompt_cache.recache_tokens_if_cold // 0),
    (.transcript_path // "")
  ] | map(tostring) | join("\u001f")' | tr -d '\r'
)"

# --- line 1: model · dir · branch ---
dirname=${cwd%[/\\]}; dirname=${dirname##*[/\\]}
branch=$(git -C "$cwd" branch --show-current 2>/dev/null)

# On narrow terminals, trim the longer of dir/branch until the line fits.
room=$(( width - ${#model} - (${#branch} > 0 ? 6 : 3) ))
d=$(visible_len "$dirname"); b=$(visible_len "$branch")
while [ $(( d + b )) -gt "$room" ] && { [ "$d" -gt 8 ] || [ "$b" -gt 8 ]; }; do
  if [ "$d" -ge "$b" ]; then d=$(( d - 1 )); else b=$(( b - 1 )); fi
done
dirname=$(truncate "$dirname" "$d"); branch=$(truncate "$branch" "$b")

dot=" ${GRAY}·${RESET} "
line1="${CYAN}${model}${RESET}${dot}${dirname}"
[ -n "$branch" ] && line1="${line1}${dot}${GREEN}${branch}${RESET}"

# --- line 2: each segment rendered at 3 detail levels (full / medium / short) ---
full=(); medium=(); short=()
add() { full+=("$1"); medium+=("$2"); short+=("$3"); }

c=$(color_for "$ctx")
# Used/total tokens stay at every detail level: it's the number that matters most.
tokens=""
if [ "${ctx_used%.*}" -gt 0 ] 2>/dev/null; then
  total=""
  [ "${ctx_size%.*}" -gt 0 ] 2>/dev/null && total="/$(fmt_tokens "$ctx_size")"
  tokens=" $(fmt_tokens "$ctx_used")${GRAY}${total}${RESET}"
fi
n=$(num "${ctx}%" "$c")
add "ctx $(bar "$ctx" "$c") ${n}${tokens}" "ctx ${n}${tokens}" "ctx ${n}${tokens}"

rate_segment() {
  local label=$1 pct=$2 resets=$3 c n reset_txt=""
  [ -z "$pct" ] && return
  c=$(color_for "$pct")
  [ -n "$resets" ] && reset_txt=" ${GRAY}(resets $(fmt_duration $(( ${resets%.*} - now ))))${RESET}"
  n=$(num "${pct}%" "$c")
  add "$label $(bar "$pct" "$c") ${n}${reset_txt}" "$label ${n}${reset_txt}" "$label ${n}"
}
rate_segment 5h "$five" "$five_reset"
rate_segment 7d "$week" "$week_reset"

# --- prompt cache ---
if [ "$pc_present" != "true" ]; then
  pc_recache=0; pc_observed=true
  IFS=$'\t' read -r pc_warm pc_ttl pc_exp <<< "$(cache_from_transcript "$transcript")"
fi
if [ -n "$pc_warm" ] && [ "$pc_observed" = "true" ]; then
  ttl_secs=300; [ "$pc_ttl" = "1h" ] && ttl_secs=3600
  remaining=$(( ${pc_exp%.*} - now ))
  if [ "$pc_warm" != "true" ] || [ "$remaining" -le 0 ]; then
    cost=""
    [ "${pc_recache%.*}" -gt 0 ] 2>/dev/null && cost=" ${GRAY}· $(fmt_tokens "$pc_recache") to rewrite${RESET}"
    n=$(num cold "$RED")
    add "cache ${n}${cost}" "cache ${n}" "cache ${n}"
  else
    c=$YELLOW; [ $(( remaining * 5 )) -gt "$ttl_secs" ] && c=$GREEN
    if [ "$remaining" -lt 600 ]; then printf -v left '%d:%02d' $(( remaining / 60 )) $(( remaining % 60 ))
    else left=$(fmt_duration "$remaining"); fi
    n=$(num "$left" "$c")
    # Keep the "cache" label even when short: after wrapping it may sit alone on a line.
    add "cache ${n} ${GRAY}of ${pc_ttl}${RESET}" "cache ${n}" "cache ${n}"
  fi
fi

# As the terminal narrows, segments wrap onto new lines. Past this many stat
# lines, drop to a less detailed level instead of wrapping further.
MAX_STAT_LINES=2

# Pack segments into lines no wider than $width, like word wrapping.
# Sets: out (newline-joined lines), nlines, too_wide (1 if a single segment exceeds $width)
wrap() {
  local sep=$1; shift
  local cur="" part candidate
  out=""; nlines=0; too_wide=0
  for part in "$@"; do
    [ "$(visible_len "$part")" -gt "$width" ] && too_wide=1
    if [ -n "$cur" ]; then candidate="${cur}${sep}${part}"; else candidate=$part; fi
    if [ -n "$cur" ] && [ "$(visible_len "$candidate")" -gt "$width" ]; then
      out+="${cur}"$'\n'; nlines=$(( nlines + 1 )); cur=$part
    else
      cur=$candidate
    fi
  done
  [ -n "$cur" ] && { out+=$cur; nlines=$(( nlines + 1 )); }
}

# Most detailed level that fits in MAX_STAT_LINES wrapped lines, else the shortest level wrapped freely.
# The short level also tightens the separator.
wrap "  ${GRAY}│${RESET}  " "${full[@]}"
if [ "$nlines" -gt "$MAX_STAT_LINES" ] || [ "$too_wide" -eq 1 ]; then
  wrap "  ${GRAY}│${RESET}  " "${medium[@]}"
  if [ "$nlines" -gt "$MAX_STAT_LINES" ] || [ "$too_wide" -eq 1 ]; then
    wrap " ${GRAY}│${RESET} " "${short[@]}"
  fi
fi

printf '%b\n%b' "$line1" "$out"
