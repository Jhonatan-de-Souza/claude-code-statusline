[🇧🇷 Português](README.md) | [🇺🇸 English](README.en.md) | [🇪🇸 Español](README.es.md) | [🇨🇳 中文](README.zh.md) | 🇯🇵 日本語

# Claude Code ステータスライン

[Claude Code](https://claude.com/claude-code) 用の2行ステータスライン。モデル名、フォルダ、gitブランチ、コンテキストウィンドウ・5時間制限・7日制限の使用率をカラーバーで表示します。

![ステータスラインのプレビュー](preview-v5.svg)

使用率70%未満は緑、70〜89%は黄色、90%以上は赤で表示されます。`(resets 3h47m)` はその制限がリセットされるまでの時間です。

表示はターミナルの幅に合わせて調整されます。ウィンドウを狭くすると項目が次の行に折り返され、2行に収まらない場合はバー、次にリセット時間を省略します。

### キャッシュ表示

最後の項目はメイン会話のプロンプトキャッシュの状態です：

- `cache 47m of 1h`：キャッシュが切れるまでの時間と使用中のTTL。
- TTLの20%以上残っていれば緑、期限が近づくと黄色、期限切れ後は赤の `cold`。期限切れ時は、次のメッセージで再びキャッシュに書き込まれるトークン数も表示します（`cold · 73k to rewrite`）。

Claude CodeはリクエストごとにTTLを決めます。Claudeサブスクリプションでプランの利用枠内なら **1時間**、追加利用のクレジット・APIキー・クラウドプロバイダーを使う場合や `FORCE_PROMPT_CACHING_5M=1` / `promptCacheTtl: "5m"` を設定した場合は **5分** です。5分キャッシュの書き込みは入力料金の1.25倍、1時間は2倍、キャッシュ読み込みは0.1倍以下です。詳しくは [How Claude Code uses prompt caching](https://code.claude.com/docs/en/prompt-caching#cache-lifetime) を参照してください。

スクリプトはClaude Code自身の `prompt_cache` データ（v2.1.251以降）を読み取ります。古いバージョンではセッションのtranscriptから推定します。

## 必要環境

- Claude Code CLI
- **Windows/macOS/Linux + Python**: `statusline-command.py` を使用（Python 3が必要、追加パッケージ不要）
- **macOS/Linux（Pythonなし）**: `statusline-command.sh` を使用（`bash`、`jq`、`git`、`awk` が必要）

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
