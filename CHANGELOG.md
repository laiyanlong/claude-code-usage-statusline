# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
