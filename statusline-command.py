#!/usr/bin/env python
"""Claude Code status line: model + dir, then colored bars for context, 5h and weekly rate limits."""
import json
import subprocess
import sys
import time

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

line2 = "  |  ".join(parts)

print(line1)
print(line2, end="")
