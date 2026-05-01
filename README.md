# claude-code-usage-statusline

A warm, Anthropic-branded **statusLine** for [Claude Code](https://code.claude.com)
that shows your token usage and rate-limit reset timers right above the prompt.

```text
~/git/products git:(main) * │ Sonnet 4.6 │ 5h [████████▌░░░░░░░]  55% ⏰1h30m │ 7d [████▌░░░░░░░░░░░]  28% ⏰2d08h │ ctx [██▌░░░░░░░░░░░░░]  18%
```

- **5h / 7d rate limits** with usage bar + reset countdown
- **Context window** usage bar
- **Current model** (Opus / Sonnet / Haiku)
- **Git branch** with dirty `*` indicator
- **16-cell gradient bar**, half-block (`▌`) precision, per-cell ANSI 256 colour
- Anthropic warm palette: `#FFD7AF → #D97757 → #AF0000`

## Requirements

- Claude Code **v2.1.92+** (rate-limit fields exposed in statusLine stdin)
- `jq`, `git`, `bash` — all standard on macOS / Linux
- A 256-colour terminal (every modern terminal qualifies)

## Install

### A) One-line script (simplest)

```bash
curl -fsSL https://raw.githubusercontent.com/laiyanlong/claude-code-usage-statusline/main/install.sh | bash
```

It downloads `statusline.sh` to `~/.claude/`, then patches `~/.claude/settings.json`
to wire it up. Existing files are backed up with a timestamp suffix. Restart
Claude Code afterwards.

### B) As a Claude Code plugin

```bash
# inside Claude Code
/plugin install laiyanlong/claude-code-usage-statusline
```

then run the bundled slash command:

```
/claude-code-usage-statusline:install
```

### C) Manual

```bash
mkdir -p ~/.claude
curl -fsSL https://raw.githubusercontent.com/laiyanlong/claude-code-usage-statusline/main/statusline.sh \
  -o ~/.claude/statusline.sh
chmod +x ~/.claude/statusline.sh
```

Then add to `~/.claude/settings.json`:

```json
{
  "statusLine": {
    "type": "command",
    "command": "bash ~/.claude/statusline.sh"
  }
}
```

## Gradient

| Bar position | Colour       | ANSI 256 | Hex      |
| ------------ | ------------ | -------- | -------- |
| 0–25%        | light apricot | 223     | #FFD7AF |
| 25–45%       | sand orange   | 216     | #FFAF87 |
| 45–65%       | Claude orange | 173     | #D7875F |
| 65–85%       | terracotta    | 166     | #D75F00 |
| 85–100%      | dark crimson  | 124     | #AF0000 |

The percentage label and frame share the colour of the highest filled cell, so
a glance tells you the severity.

## Customise

Edit `~/.claude/statusline.sh` directly. Common tweaks:

- **Bar width** — change `width="${2:-16}"` in `make_bar` to 8, 24, etc.
- **Gradient stops** — adjust the cutoffs in `cell_color()` and `pct_color()`.
- **Half-block character** — replace `▌` with `▎` (¼) or `▊` (¾) for different
  resolution.
- **Hide a section** — comment out the `5h` / `7d` / `ctx` block.

## Uninstall

```bash
curl -fsSL https://raw.githubusercontent.com/laiyanlong/claude-code-usage-statusline/main/uninstall.sh | bash
```

Or manually delete `~/.claude/statusline.sh` and remove the `statusLine` key
from `~/.claude/settings.json`.

## Why does the 5h / 7d row not show?

You're on Claude Code &lt; v2.1.92, which doesn't expose `rate_limits` in the
statusLine stdin payload. Update Claude Code; the script auto-detects and
hides the section gracefully on older builds.

## Acknowledgements

Inspired by [`ccusage`](https://github.com/ryoppippi/ccusage),
[`claude-code-usage-bar`](https://github.com/leeguooooo/claude-code-usage-bar),
and [`ccstatusline`](https://github.com/sirmalloc/ccstatusline). Built using
the official Claude Code [statusLine](https://code.claude.com/docs/en/statusline)
hook.

## License

MIT — see [LICENSE](LICENSE).
