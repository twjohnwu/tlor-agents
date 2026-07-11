#!/usr/bin/env bash
# install.sh — copy the TLOR agent roles into ~/.claude/agents/ (no plugin system needed).
# Usage: ./install.sh [--dry-run] [--force] [--uninstall]
# Prefer the plugin route when possible:
#   /plugin marketplace add twjohnwu/tlor-agents   then   /plugin install tlor-agents@tlor
set -euo pipefail

SRC="$(cd "$(dirname "$0")/agents" && pwd)"
DEST="$HOME/.claude/agents"
DRY=0; FORCE=0; UNINSTALL=0
for a in "$@"; do
  case "$a" in
    --dry-run) DRY=1;;
    --force) FORCE=1;;
    --uninstall) UNINSTALL=1;;
    *) echo "unknown arg: $a" >&2; exit 1;;
  esac
done

ROLES=$(cd "$SRC" && ls ./*.md | sed 's|^\./||')

if [ "$UNINSTALL" -eq 1 ]; then
  for f in $ROLES; do
    if [ -f "$DEST/$f" ]; then
      [ "$DRY" -eq 1 ] && echo "would remove $DEST/$f" || { rm "$DEST/$f"; echo "removed $DEST/$f"; }
    fi
  done
  if [ "$DRY" -eq 1 ]; then echo "uninstall dry-run done (nothing removed)."; else echo "uninstall done."; fi
  exit 0
fi

mkdir -p "$DEST"
conflicts=""
for f in $ROLES; do
  if [ -f "$DEST/$f" ] && ! cmp -s "$SRC/$f" "$DEST/$f"; then
    conflicts="$conflicts $f"
  fi
done
if [ -n "$conflicts" ] && [ "$FORCE" -ne 1 ]; then
  echo "ABORT: these files already exist at $DEST with different content:$conflicts" >&2
  echo "Re-run with --force to overwrite, or remove them first." >&2
  exit 1
fi

for f in $ROLES; do
  [ "$DRY" -eq 1 ] && echo "would install $DEST/$f" || { cp "$SRC/$f" "$DEST/$f"; echo "installed $DEST/$f"; }
done
[ "$DRY" -eq 1 ] && { echo "dry-run done (nothing written)."; exit 0; }
echo "install done: $(echo $ROLES | wc -w | tr -d ' ') roles in $DEST"
echo "NOTE: open a NEW Claude Code session to load the roles (agent definitions are read at session start)."
