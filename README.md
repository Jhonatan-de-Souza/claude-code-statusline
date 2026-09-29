🇧🇷 Português | [🇺🇸 English](README.en.md) | [🇪🇸 Español](README.es.md) | [🇨🇳 中文](README.zh.md) | [🇯🇵 日本語](README.ja.md)

# Status Line do Claude Code

Barra de status de duas linhas para o [Claude Code](https://claude.com/claude-code) mostrando modelo, pasta, branch do git e barras coloridas de uso: janela de contexto, limite de 5 horas e limite de 7 dias.

![prévia da status line](preview.svg)

Barras ficam verdes abaixo de 70%, amarelas entre 70-89% e vermelhas a partir de 90%.

### Indicador de cache

No fim da segunda linha aparece o estado do cache de prompt da última chamada à API:

- `Cache ● 4m12s left (5m) 92% hit` — tempo restante antes do cache expirar, o TTL em uso (5 minutos ou 1 hora) e quanto do input veio do cache.
- Verde enquanto resta mais de 20% do TTL, amarelo perto de expirar e `● cold` em vermelho depois que expirou (a próxima mensagem vai reprocessar todo o contexto).

O tempo é estimado a partir do transcript da sessão.

## Requisitos

- Claude Code CLI
- **Windows/macOS/Linux com Python**: use `statusline-command.py` (precisa de Python 3, sem pacotes extras)
- **macOS/Linux sem Python**: use `statusline-command.sh` (precisa de `bash`, `jq`, `git`, `awk`)

## Instalação

1. Baixe `statusline-command.py` (ou `.sh`) desta pasta.
2. Coloque na pasta de configuração do Claude Code: `~/.claude/statusline-command.py`
3. Abra `~/.claude/settings.json` (crie se não existir) e adicione:

**Versão Python:**
```json
{
  "statusLine": {
    "type": "command",
    "command": "python ~/.claude/statusline-command.py"
  }
}
```

**Versão Bash:**
```json
{
  "statusLine": {
    "type": "command",
    "command": "bash ~/.claude/statusline-command.sh"
  }
}
```

4. No Windows, `python` precisa estar no PATH (ou use `py`/caminho completo, ex: `"command": "python C:\\Users\\<voce>\\.claude\\statusline-command.py"`).
5. Reinicie o Claude Code. A status line aparece na parte inferior do terminal.

Se o `settings.json` já tiver outras chaves, só mescle o bloco `statusLine` — não sobrescreva o resto do arquivo.

## Desinstalar

Remova o bloco `statusLine` do `settings.json` (ou apague o arquivo inteiro se só tinha essa chave) e reinicie o Claude Code.
