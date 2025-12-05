#!/usr/bin/env bash
set -euo pipefail

# Destructive VS Code reset for Windows (Git Bash). Backs up settings + extensions list,
# then deletes VS Code user data and local extensions. Does NOT touch your code/projects
# unless you pass --delete-folder explicitly.

CONFIRM=""
DELETE_TARGETS=()

while [[ ${1:-} != "" ]]; do
  case "$1" in
    --yes|-y)
      CONFIRM="YES"
      shift
      ;;
    --delete-folder)
      shift
      [[ ${1:-} != "" ]] || { echo "--delete-folder requires a path" >&2; exit 2; }
      DELETE_TARGETS+=("$1")
      shift
      ;;
    *)
      echo "Unknown arg: $1" >&2
      exit 2
      ;;
  esac
done

cat <<'EOF'
This will:
  - Stop all running VS Code instances
  - BACKUP your VS Code User settings and list of extensions
  - DELETE VS Code user data under %APPDATA%\Code
  - DELETE all local extensions under %USERPROFILE%\.vscode\extensions

Your project folders/code WILL NOT be deleted unless you provided --delete-folder <PATH>.
EOF

if [[ "$CONFIRM" != "YES" ]]; then
  read -r -p "Type YES to proceed: " CONFIRM
fi

if [[ "$CONFIRM" != "YES" ]]; then
  echo "Cancelled."
  exit 1
fi

# Create and run a temporary PowerShell script to avoid quoting issues.
TMPPS=$(mktemp -t reset-vscode-XXXXXX.ps1)
trap 'rm -f "$TMPPS"' EXIT

cat > "$TMPPS" <<'POWERSHELL'
$ErrorActionPreference = 'SilentlyContinue'

# Timestamped backup folder under USERPROFILE
$ts = Get-Date -Format 'yyyyMMdd-HHmmss'
$backup = Join-Path $env:USERPROFILE "vscode-backup-$ts"
New-Item -ItemType Directory -Force -Path $backup | Out-Null

# Export extensions list (best-effort)
try {
  code --list-extensions | Out-File -Encoding utf8 (Join-Path $backup 'extensions.txt')
} catch {}

# Backup User settings if present
$UserDir = Join-Path $env:APPDATA 'Code\User'
if (Test-Path $UserDir) {
  Copy-Item -Recurse -Force $UserDir (Join-Path $backup 'User') -ErrorAction SilentlyContinue
}

# Stop VS Code
Get-Process -Name Code -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 1

# Delete VS Code data and local extensions
Remove-Item -Recurse -Force (Join-Path $env:APPDATA 'Code') -ErrorAction SilentlyContinue
Remove-Item -Recurse -Force (Join-Path $env:USERPROFILE '.vscode\extensions') -ErrorAction SilentlyContinue

POWERSHELL

# Execute the PowerShell reset
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$TMPPS"

echo "Core VS Code reset completed. Backup saved under %USERPROFILE%\\vscode-backup-<timestamp>."

# Optionally delete specified folders (very destructive)
if (( ${#DELETE_TARGETS[@]} > 0 )); then
  echo "Deleting project folders:"
  for p in "${DELETE_TARGETS[@]}"; do
    echo "  - $p"
  done
  read -r -p "Final confirmation: type DELETE to remove these folders: " REALLY
  if [[ "$REALLY" == "DELETE" ]]; then
    for p in "${DELETE_TARGETS[@]}"; do
      powershell.exe -NoProfile -Command "if (Test-Path \"$p\") { Remove-Item -Recurse -Force \"$p\" }"
    done
    echo "Selected folders deleted."
  else
    echo "Skipped deleting project folders."
  fi
fi

echo "Done. You can now start VS Code, or run scripts/vscode-fresh.sh for a clean session."
