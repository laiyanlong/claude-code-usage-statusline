---
description: Remove the usage statusLine and revert ~/.claude/settings.json
---

Uninstall the `claude-code-usage-statusline`:

1. Delete `~/.claude/statusline.sh` if it exists (back up first).
2. Edit `~/.claude/settings.json` with `jq 'del(.statusLine)'` — back up first.
3. Tell the user the statusLine has been removed and to restart Claude Code.
