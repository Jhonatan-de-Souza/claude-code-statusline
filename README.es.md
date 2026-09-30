[🇧🇷 Português](README.md) | [🇺🇸 English](README.en.md) | 🇪🇸 Español | [🇨🇳 中文](README.zh.md) | [🇯🇵 日本語](README.ja.md)

# Barra de Estado de Claude Code

Barra de estado de dos líneas para [Claude Code](https://claude.com/claude-code) que muestra modelo, carpeta, rama de git y barras de uso con color para la ventana de contexto, el límite de 5 horas y el límite de 7 días.

![vista previa de la barra de estado](preview-v5.svg)

Los números se ponen verdes por debajo de 70%, amarillos entre 70-89% y rojos a partir de 90%. `(resets 3h47m)` es cuándo se reinicia ese límite.

La barra de estado se ajusta al ancho del terminal. Al estrechar la ventana, los segmentos pasan a una nueva línea. Si aun así no caben en dos líneas, oculta las barras y luego los tiempos de reinicio.

### Indicador de caché

El último segmento muestra la caché de prompt de la conversación principal:

- `cache 47m of 1h`: tiempo hasta que la caché se enfríe y el TTL en uso.
- Verde mientras quede más del 20% del TTL, amarillo cuando está por expirar y `cold` en rojo cuando ya expiró. En frío también muestra cuántos tokens tu próximo mensaje volverá a escribir en la caché (`cold · 73k to rewrite`).

Claude Code elige el TTL por petición: **1 hora** con una suscripción de Claude dentro del uso del plan, **5 minutos** cuando usas créditos (uso extra), una clave de API o un proveedor de nube, o cuando defines `FORCE_PROMPT_CACHING_5M=1` / `promptCacheTtl: "5m"`. Escribir en la caché de 5 minutos cuesta 1,25x el precio de input y en la de 1 hora 2x; las lecturas de caché cuestan 0,1x o menos. Ver [How Claude Code uses prompt caching](https://code.claude.com/docs/en/prompt-caching#cache-lifetime).

El script lee los datos `prompt_cache` del propio Claude Code (v2.1.251+). En versiones anteriores lo estima a partir del transcript de la sesión.

## Requisitos

- Claude Code CLI
- **Windows/macOS/Linux con Python**: usa `statusline-command.py` (necesita Python 3, sin paquetes extra)
- **macOS/Linux sin Python**: usa `statusline-command.sh` (necesita `bash`, `jq`, `git`, `awk`)

## Instalación

1. Descarga `statusline-command.py` (o `.sh`) de esta carpeta.
2. Colócalo en la carpeta de configuración de Claude Code: `~/.claude/statusline-command.py`
3. Abre `~/.claude/settings.json` (créalo si no existe) y añade:

**Versión Python:**
```json
{
  "statusLine": {
    "type": "command",
    "command": "python ~/.claude/statusline-command.py"
  }
}
```

**Versión Bash:**
```json
{
  "statusLine": {
    "type": "command",
    "command": "bash ~/.claude/statusline-command.sh"
  }
}
```

4. En Windows, `python` debe estar en el PATH (o usa `py`/ruta completa, ej: `"command": "python C:\\Users\\<tu>\\.claude\\statusline-command.py"`).
5. Reinicia Claude Code. La barra de estado aparece en la parte inferior de la terminal.

Si `settings.json` ya tiene otras claves, solo combina el bloque `statusLine` — no sobrescribas el resto del archivo.

## Desinstalar

Elimina el bloque `statusLine` de `settings.json` (o borra el archivo entero si solo tenía esa clave) y reinicia Claude Code.
