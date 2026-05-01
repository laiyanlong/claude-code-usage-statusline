#!/usr/bin/env bash
# Installer for claude-code-usage-statusline
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/laiyanlong/claude-code-usage-statusline/main/install.sh | bash
#
# Downloads statusline.sh into ~/.claude/ and patches ~/.claude/settings.json
# so Claude Code uses it as the statusLine.

set -euo pipefail

REPO_RAW="https://raw.githubusercontent.com/laiyanlong/claude-code-usage-statusline/main"
TARGET_DIR="${HOME}/.claude"
TARGET_SH="${TARGET_DIR}/statusline.sh"
SETTINGS="${TARGET_DIR}/settings.json"

bold() { printf "\033[1m%s\033[0m\n" "$*"; }
green() { printf "\033[32m%s\033[0m\n" "$*"; }
red()   { printf "\033[31m%s\033[0m\n" "$*" >&2; }

bold "==> claude-code-usage-statusline installer"

# 1. Dependency check
if ! command -v jq >/dev/null 2>&1; then
  red "jq not found. Please install jq (brew install jq / apt install jq) and re-run."
  exit 1
fi

# 2. Download statusline.sh
mkdir -p "${TARGET_DIR}"
if [ -f "${TARGET_SH}" ]; then
  cp "${TARGET_SH}" "${TARGET_SH}.bak.$(date +%Y%m%d-%H%M%S)"
  echo "Existing statusline.sh backed up."
fi
echo "Downloading statusline.sh ..."
curl -fsSL "${REPO_RAW}/statusline.sh" -o "${TARGET_SH}"
chmod +x "${TARGET_SH}"
green "Wrote ${TARGET_SH}"

# 3. Patch settings.json
if [ ! -f "${SETTINGS}" ]; then
  echo '{}' > "${SETTINGS}"
fi
cp "${SETTINGS}" "${SETTINGS}.bak.$(date +%Y%m%d-%H%M%S)"

tmp=$(mktemp)
jq --arg cmd "bash ${TARGET_SH}" \
   '.statusLine = {"type":"command","command":$cmd}' \
   "${SETTINGS}" > "${tmp}" && mv "${tmp}" "${SETTINGS}"
green "Patched ${SETTINGS}"

# 4. Done
bold "==> Done."
echo "Reopen Claude Code; the statusLine appears above the prompt."
echo "Requires Claude Code v2.1.92+ to show 5h / 7d rate-limit bars."
