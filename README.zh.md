[🇧🇷 Português](README.md) | [🇺🇸 English](README.en.md) | [🇪🇸 Español](README.es.md) | 🇨🇳 中文 | [🇯🇵 日本語](README.ja.md)

# Claude Code 状态栏

为 [Claude Code](https://claude.com/claude-code) 提供的两行状态栏，显示模型、目录、git 分支，以及上下文窗口、5小时限额和7天限额的彩色用量条。

![状态栏预览](preview.svg)

用量低于 70% 显示绿色，70-89% 显示黄色，90% 及以上显示红色。

## 环境要求

- Claude Code CLI
- **Windows/macOS/Linux + Python**：使用 `statusline-command.py`（需要 Python 3，无需额外依赖）
- **macOS/Linux 无 Python**：使用 `statusline-command.sh`（需要 `bash`、`jq`、`git`）

## 安装步骤

1. 从此文件夹下载 `statusline-command.py`（或 `.sh`）。
2. 放入 Claude Code 配置目录：`~/.claude/statusline-command.py`
3. 打开 `~/.claude/settings.json`（不存在则新建），添加以下内容：

**Python 版本：**
```json
{
  "statusLine": {
    "type": "command",
    "command": "python ~/.claude/statusline-command.py"
  }
}
```

**Bash 版本：**
```json
{
  "statusLine": {
    "type": "command",
    "command": "bash ~/.claude/statusline-command.sh"
  }
}
```

4. Windows 上 `python` 需要在 PATH 中（或使用 `py`/完整路径，例如：`"command": "python C:\\Users\\<你>\\.claude\\statusline-command.py"`）。
5. 重启 Claude Code，状态栏会显示在终端底部。

如果 `settings.json` 已有其他配置项，只需合并 `statusLine` 部分——不要覆盖文件其余内容。

## 卸载

从 `settings.json` 中移除 `statusLine` 部分（如果文件只有这一项，可直接删除整个文件），然后重启 Claude Code。
