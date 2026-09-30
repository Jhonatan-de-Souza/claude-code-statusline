[🇧🇷 Português](README.md) | [🇺🇸 English](README.en.md) | [🇪🇸 Español](README.es.md) | 🇨🇳 中文 | [🇯🇵 日本語](README.ja.md)

# Claude Code 状态栏

为 [Claude Code](https://claude.com/claude-code) 提供的两行状态栏，显示模型、目录、git 分支，以及上下文窗口、5小时限额和7天限额的彩色用量条。

![状态栏预览](preview-v5.svg)

数值低于 70% 显示绿色，70-89% 显示黄色，90% 及以上显示红色。`(resets 3h47m)` 表示该限额何时重置。

状态栏会适应终端宽度。窗口变窄时，各段会自动换到下一行；如果两行仍放不下，会先隐藏用量条，再隐藏重置时间。

### 缓存指示器

最后一段显示主对话的提示缓存状态：

- `cache 47m of 1h`：距离缓存失效的时间和当前 TTL。
- 剩余时间超过 TTL 的 20% 时为绿色，即将过期时为黄色，过期后显示红色 `cold`。失效时还会显示下一条消息需要重新写入缓存的 token 数（`cold · 73k to rewrite`）。

Claude Code 按请求选择 TTL：Claude 订阅在套餐额度内为 **1 小时**；使用额外用量额度、API key 或云服务商时为 **5 分钟**，设置 `FORCE_PROMPT_CACHING_5M=1` / `promptCacheTtl: "5m"` 时也是 5 分钟。5 分钟缓存写入价格为输入价格的 1.25 倍，1 小时为 2 倍；缓存读取为 0.1 倍或更低。详见 [How Claude Code uses prompt caching](https://code.claude.com/docs/en/prompt-caching#cache-lifetime)。

脚本读取 Claude Code 自带的 `prompt_cache` 数据（v2.1.251+）。旧版本则根据会话 transcript 估算。

## 环境要求

- Claude Code CLI
- **Windows/macOS/Linux + Python**：使用 `statusline-command.py`（需要 Python 3，无需额外依赖）
- **macOS/Linux 无 Python**：使用 `statusline-command.sh`（需要 `bash`、`jq`、`git`、`awk`）

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
