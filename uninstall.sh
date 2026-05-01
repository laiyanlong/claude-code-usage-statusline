#!/usr/bin/env bash
# Removes statusline.sh and the statusLine entry from settings.json.
# Usage: curl -fsSL .../uninstall.sh | bash
set -euo pipefail

TARGET_DIR="${HOME}/.claude"
TARGET_SH="${TARGET_DIR}/statusline.sh"
SETTINGS="${TARGET_DIR}/settings.json"

if [ -f "${TARGET_SH}" ]; then
  rm -f "${TARGET_SH}"
  echo "Removed ${TARGET_SH}"
fi

if [ -f "${SETTINGS}" ] && command -v jq >/dev/null 2>&1; then
  cp "${SETTINGS}" "${SETTINGS}.bak.$(date +%Y%m%d-%H%M%S)"
  tmp=$(mktemp)
  jq 'del(.statusLine)' "${SETTINGS}" > "${tmp}" && mv "${tmp}" "${SETTINGS}"
  echo "Removed statusLine entry from ${SETTINGS}"
fi

echo "Uninstalled."
