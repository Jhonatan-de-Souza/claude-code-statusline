[🇧🇷 Português](README.md) | [🇺🇸 English](README.en.md) | [🇪🇸 Español](README.es.md) | [🇨🇳 中文](README.zh.md) | 🇯🇵 日本語

# Claude Code ステータスライン

[Claude Code](https://claude.com/claude-code) 用の2行ステータスライン。モデル名、フォルダ、gitブランチ、コンテキストウィンドウ・5時間制限・7日制限の使用率をカラーバーで表示します。

![ステータスラインのプレビュー](preview.svg)

使用率70%未満は緑、70〜89%は黄色、90%以上は赤で表示されます。

## 必要環境

- Claude Code CLI
- **Windows/macOS/Linux + Python**: `statusline-command.py` を使用（Python 3が必要、追加パッケージ不要）
- **macOS/Linux（Pythonなし）**: `statusline-command.sh` を使用（`bash`、`jq`、`git` が必要）

## インストール

1. このフォルダから `statusline-command.py`（または `.sh`）をダウンロード。
2. Claude Codeの設定フォルダに配置: `~/.claude/statusline-command.py`
3. `~/.claude/settings.json` を開き（なければ作成）、以下を追加:

**Python版:**
```json
{
  "statusLine": {
    "type": "command",
    "command": "python ~/.claude/statusline-command.py"
  }
}
```

**Bash版:**
```json
{
  "statusLine": {
    "type": "command",
    "command": "bash ~/.claude/statusline-command.sh"
  }
}
```

4. Windowsでは `python` がPATHに通っている必要があります（または `py` やフルパスを使用、例: `"command": "python C:\\Users\\<user>\\.claude\\statusline-command.py"`）。
5. Claude Codeを再起動。ターミナル下部にステータスラインが表示されます。

`settings.json` に他の設定がすでにある場合は、`statusLine` ブロックだけをマージしてください。ファイル全体を上書きしないように。

## アンインストール

`settings.json` から `statusLine` ブロックを削除し（そのキーしかない場合はファイルごと削除可）、Claude Codeを再起動してください。
