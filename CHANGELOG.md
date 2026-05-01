# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.2.0] - 2026-05-01

### Added

- **Environment-variable customisation** — no need to edit the script:
  - `STATUSLINE_BAR_WIDTH` — bar cell count (default 16).
  - `STATUSLINE_THEME` — `warm` (default) · `classic` · `neon` · `mono`.
  - `STATUSLINE_PULSE` — `0` static · `1` blink danger cells (≥85%) · `2`
    wave animation that walks across the bar each second.
  - `STATUSLINE_HIDE` — comma list to skip sections (e.g. `7d,ctx,path`).
  - `STATUSLINE_HALF_BLOCK` — half-cell character (`▌`/`▎`/`▊`/…).
  - `STATUSLINE_SEP` — section separator character (`│`/`•`/`▸`/…).
- 5-frame animated SVG preview with crossfade and a blinking danger cell.
- Comparison table in README vs. `ccusage`, `claude-statusbar`,
  `claude-code-usage-bar`, `ccstatusline`.

### Changed

- Theme colour stops are now driven by lookup variables `C0..C4` and
  `ACCENT`, making it trivial to add new themes.

[0.2.0]: https://github.com/laiyanlong/claude-code-usage-statusline/releases/tag/v0.2.0

## [0.1.0] - 2026-05-01

### Added

- 16-cell gradient progress bars with half-block (`▌`) precision (1.5%
  effective resolution) for 5-hour and 7-day rate limits.
- Context window usage bar.
- Reset countdown timers (`⏰2h14m`, `⏰3d05h`, `⏰now`).
- Anthropic warm palette (`#FFD7AF` → `#D97757` → `#AF0000`) with per-cell
  gradient colour ramping.
- Current model name (Opus / Sonnet / Haiku) coloured Claude orange.
- Robbyrussell-style cwd + git branch + dirty `*` indicator.
- `install.sh` / `uninstall.sh` one-line installers with timestamped
  backups of `settings.json`.
- Claude Code plugin manifest (`.claude-plugin/plugin.json`) with
  `/install` and `/uninstall` slash commands.
- Static SVG preview and animated SMIL preview in README.
- Graceful fallback when `rate_limits` field is missing (Claude Code
  &lt; v2.1.92).

[0.1.0]: https://github.com/laiyanlong/claude-code-usage-statusline/releases/tag/v0.1.0
