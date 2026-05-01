---
description: Install the warm-gradient usage statusLine into ~/.claude/
---

Install the `claude-code-usage-statusline` script into `~/.claude/statusline.sh`
and patch `~/.claude/settings.json` so Claude Code uses it as the statusLine.

Steps to perform:

1. Confirm `jq` is available (`command -v jq`). If missing, instruct the user
   to install it (`brew install jq` on macOS, `apt install jq` on Debian) and
   stop.
2. Resolve the plugin root: the script lives at `${CLAUDE_PLUGIN_ROOT}/statusline.sh`.
3. If `~/.claude/statusline.sh` already exists, back it up with a timestamp suffix.
4. Copy `${CLAUDE_PLUGIN_ROOT}/statusline.sh` to `~/.claude/statusline.sh` and
   `chmod +x` it.
5. Patch `~/.claude/settings.json` (create with `{}` if missing) using `jq` to
   set `.statusLine = {"type":"command","command":"bash <abs path>"}`. Back up
   the original first.
6. Tell the user to restart Claude Code and that rate-limit bars require
   Claude Code v2.1.92+.
