[🇧🇷 Português](README.md) | 🇺🇸 English | [🇪🇸 Español](README.es.md) | [🇨🇳 中文](README.zh.md) | [🇯🇵 日本語](README.ja.md)

# Claude Code Status Line

Compact two-line status line for [Claude Code](https://claude.com/claude-code) showing model, folder, git branch, and color-coded usage for context window, 5-hour limit, and 7-day limit.

![status line preview](preview-v5.svg)

Numbers turn green under 70%, yellow at 70-89%, red at 90%+. `(resets 3h47m)` is when that limit resets.

The status line fits the terminal width. As the window narrows, segments wrap onto a new line. If they still don't fit in two lines, it drops the bars, then the reset times.

### Cache indicator

The last segment shows the prompt cache of the main conversation:

- `cache 47m of 1h`: time until the cache goes cold and the TTL in use.
- Green while more than 20% of the TTL remains, yellow when it's about to expire, red `cold` once it has expired. When cold it also shows how many tokens your next message will write to the cache again (`cold · 73k to rewrite`).

Claude Code picks the TTL per request: **1 hour** on a Claude subscription within plan usage, **5 minutes** when you're on usage credits (extra usage), an API key or a cloud provider, or when you set `FORCE_PROMPT_CACHING_5M=1` / `promptCacheTtl: "5m"`. A 5-minute cache write costs 1.25x the input price and a 1-hour write costs 2x; cache reads cost 0.1x or less. See [How Claude Code uses prompt caching](https://code.claude.com/docs/en/prompt-caching#cache-lifetime).

The script reads Claude Code's own `prompt_cache` data (v2.1.251+). On older versions it estimates from the session transcript.

## Requirements

- Claude Code CLI
- **Windows/macOS/Linux with Python**: use `statusline-command.py` (needs Python 3, no extra packages)
- **macOS/Linux without Python**: use `statusline-command.sh` (needs `bash`, `jq`, `git`, `awk`)

## Install

1. Download `statusline-command.py` (or `.sh`) from this folder.
2. Place it in your Claude Code config folder: `~/.claude/statusline-command.py`
3. Open `~/.claude/settings.json` (create it if missing) and add:

**Python version:**
```json
{
  "statusLine": {
    "type": "command",
    "command": "python ~/.claude/statusline-command.py"
  }
}
```

**Bash version:**
```json
{
  "statusLine": {
    "type": "command",
    "command": "bash ~/.claude/statusline-command.sh"
  }
}
```

4. On Windows, `python` must be on PATH (or use `py`/full path instead, e.g. `"command": "python C:\\Users\\<you>\\.claude\\statusline-command.py"`).
5. Restart Claude Code. Status line appears at the bottom of the terminal.

If `settings.json` already has other keys, just merge the `statusLine` block in — don't overwrite the rest of the file.

## Uninstall

Remove the `statusLine` block from `settings.json` (or delete the whole file if it only had that key), restart Claude Code.
