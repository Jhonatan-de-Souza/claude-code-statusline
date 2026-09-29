#!/usr/bin/env python
"""Claude Code status line: model + dir, then colored bars for context, 5h and weekly rate limits, plus cache warmth."""
import json
import subprocess
import sys
import time
from datetime import datetime

# Windows defaults stdin/stdout to cp1252, which mangles UTF-8 JSON input
# (accented paths) and can't encode emoji/block chars on output.
sys.stdin.reconfigure(encoding="utf-8")
sys.stdout.reconfigure(encoding="utf-8")

GREEN, YELLOW, RED, CYAN, GRAY, RESET = (
    "\033[32m", "\033[33m", "\033[31m", "\033[36m", "\033[2m", "\033[0m",
)
BAR_WIDTH = 10


def color_for(pct):
    if pct >= 90:
        return RED
    if pct >= 70:
        return YELLOW
    return GREEN


def bar(pct, color):
    pct = min(pct, 100)
    filled = pct * BAR_WIDTH // 100
    empty = BAR_WIDTH - filled
    return f"{color}{'█' * filled}{GRAY}{'░' * empty}{RESET}"


def pct_text(pct, color):
    return f"{color}{pct}%{RESET}"


def fmt_tokens(n):
    if n >= 1000:
        return f"{n / 1000:.1f}k"
    return str(n)


def fmt_reset(ts):
    if not ts:
        return "--"
    diff = max(0, int(ts) - int(time.time()))
    h, m = divmod(diff // 60, 60)
    return f"{h}h{m:02d}m"


def cache_status(transcript_path):
    """Estimate prompt-cache warmth from the last main-thread API call in the transcript."""
    if not transcript_path:
        return None
    try:
        with open(transcript_path, "rb") as f:
            f.seek(0, 2)
            f.seek(max(0, f.tell() - 512 * 1024))
            lines = f.read().decode("utf-8", errors="ignore").splitlines()
    except OSError:
        return None

    last_ts, last_usage, ttl = None, None, None
    for raw in reversed(lines):
        if '"assistant"' not in raw:
            continue
        try:
            entry = json.loads(raw)
        except ValueError:
            continue
        if entry.get("type") != "assistant" or entry.get("isSidechain"):
            continue
        usage = (entry.get("message") or {}).get("usage")
        if not usage:
            continue
        if last_ts is None:
            last_ts, last_usage = entry.get("timestamp"), usage
        creation = usage.get("cache_creation") or {}
        if creation.get("ephemeral_1h_input_tokens"):
            ttl = 3600
        elif creation.get("ephemeral_5m_input_tokens"):
            ttl = 300
        if ttl:
            break
    if not last_ts:
        return None

    try:
        called_at = datetime.fromisoformat(last_ts.replace("Z", "+00:00")).timestamp()
    except ValueError:
        return None
    ttl = ttl or 300
    remaining = int(called_at + ttl - time.time())

    read = last_usage.get("cache_read_input_tokens") or 0
    total = read + (last_usage.get("cache_creation_input_tokens") or 0) + (last_usage.get("input_tokens") or 0)
    hit = f" {GRAY}{read * 100 // total}% hit{RESET}" if total else ""
    ttl_label = "1h" if ttl == 3600 else "5m"

    if remaining <= 0:
        return f"Cache {RED}● cold{RESET} {GRAY}({ttl_label}){RESET}{hit}"
    color = GREEN if remaining > ttl * 0.2 else YELLOW
    m, s = divmod(remaining, 60)
    left = f"{m}m{s:02d}s" if m < 10 else f"{m}m"
    return f"Cache {color}● {left} left{RESET} {GRAY}({ttl_label}){RESET}{hit}"


data = json.load(sys.stdin)

model = data.get("model", {}).get("display_name", "?")
cwd = data.get("workspace", {}).get("current_dir", "")
dirname = cwd.rstrip("/\\").split("/")[-1].split("\\")[-1] or cwd

branch = ""
try:
    branch = subprocess.check_output(
        ["git", "-C", cwd, "branch", "--show-current"],
        text=True, stderr=subprocess.DEVNULL,
    ).strip()
except Exception:
    pass

line1 = f"{CYAN}[{model}]{RESET} \U0001F4C1 {dirname}"
if branch:
    line1 += f" | \U0001F33F {branch}"

ctx_window = data.get("context_window", {}) or {}
ctx = int(ctx_window.get("used_percentage") or 0)
ctx_color = color_for(ctx)
ctx_used = ctx_window.get("total_input_tokens")
ctx_size = ctx_window.get("context_window_size")
ctx_tokens = f" ({fmt_tokens(ctx_used)}/{fmt_tokens(ctx_size)})" if ctx_used and ctx_size else ""
parts = [f"Ctx {bar(ctx, ctx_color)} {pct_text(ctx, ctx_color)}{ctx_tokens}"]

rate_limits = data.get("rate_limits") or {}

five = rate_limits.get("five_hour", {}).get("used_percentage")
if five is not None:
    five_i = int(five)
    five_color = color_for(five_i)
    five_reset = fmt_reset(rate_limits.get("five_hour", {}).get("resets_at"))
    parts.append(
        f"5h {bar(five_i, five_color)} {pct_text(five_i, five_color)} (resets {five_reset})"
    )

week = rate_limits.get("seven_day", {}).get("used_percentage")
if week is not None:
    week_i = int(week)
    week_color = color_for(week_i)
    week_reset = fmt_reset(rate_limits.get("seven_day", {}).get("resets_at"))
    parts.append(
        f"7d {bar(week_i, week_color)} {pct_text(week_i, week_color)} (resets {week_reset})"
    )

cache = cache_status(data.get("transcript_path"))
if cache:
    parts.append(cache)

line2 = "  |  ".join(parts)

print(line1)
print(line2, end="")
