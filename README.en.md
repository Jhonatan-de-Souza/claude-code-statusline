[🇧🇷 Português](README.md) | 🇺🇸 English | [🇪🇸 Español](README.es.md) | [🇨🇳 中文](README.zh.md) | [🇯🇵 日本語](README.ja.md)

# Claude Code Status Line

Two-line status line for [Claude Code](https://claude.com/claude-code) showing model, folder, git branch, and colored usage bars for context window, 5-hour limit, and 7-day limit.

![status line preview](preview.svg)

The rate-limit bars (5h and weekly) turn green under 70%, yellow at 70-89%, red at 90%+. The context bar warns earlier (yellow from 30%, red from 50%): filling the window forces a fresh session, while a rate limit only costs waiting. All four thresholds sit at the top of the script, in `CONTEXT_THRESHOLDS` and `RATE_LIMIT_THRESHOLDS` (`CTX_YELLOW`/`CTX_RED` and `RATE_YELLOW`/`RATE_RED` in the bash version).

## Requirements

- Claude Code CLI
- **Windows/macOS/Linux with Python**: use `statusline-command.py` (needs Python 3, no extra packages)
- **macOS/Linux without Python**: use `statusline-command.sh` (needs `bash`, `jq`, `git`)

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
