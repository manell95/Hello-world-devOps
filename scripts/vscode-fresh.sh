#!/usr/bin/env bash
set -euo pipefail

# Launch VS Code with a completely fresh, isolated profile (non-destructive).
# Works on Windows Git Bash as well. This does NOT delete anything.

FRESH_ROOT="$HOME/.vscode-fresh"
USER_DATA_DIR="$FRESH_ROOT/user-data"
EXT_DIR="$FRESH_ROOT/extensions"

mkdir -p "$USER_DATA_DIR" "$EXT_DIR"

echo "Starting VS Code with fresh profile..."
echo "User data dir: $USER_DATA_DIR"
echo "Extensions dir: $EXT_DIR"

if ! command -v code >/dev/null 2>&1; then
  echo "Error: 'code' CLI not found. In VS Code, press F1 → 'Shell Command: Install \"code\" command in PATH' (macOS) or ensure VS Code CLI is installed on Windows." >&2
  exit 1
fi

exec code \
  --user-data-dir "$USER_DATA_DIR" \
  --extensions-dir "$EXT_DIR"
