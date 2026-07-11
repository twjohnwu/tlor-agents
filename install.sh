#!/usr/bin/env bash
# install.sh — copy the TLOR agent roles into ~/.claude/agents/ (no plugin system needed).
# Usage: ./install.sh [--dry-run] [--force] [--uninstall]
# Prefer the plugin route when possible:
#   /plugin marketplace add twjohnwu/tlor-agents   then   /plugin install tlor-agents@tlor
set -euo pipefail

: "${HOME:?HOME is not set — refusing to guess an install location}"
SRC="$(cd "$(dirname "$0")/agents" && pwd)"
DEST="$HOME/.claude/agents"
MANIFEST="$DEST/.tlor-manifest"
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
  # Remove what was actually installed (manifest), not what the current
  # checkout happens to contain; fall back to the checkout list if no
  # manifest exists (pre-1.1.0 installs).
  if [ -f "$MANIFEST" ]; then REMOVE=$(cat "$MANIFEST"); else REMOVE=$ROLES; fi
  for f in $REMOVE; do
    if [ -f "$DEST/$f" ]; then
      [ "$DRY" -eq 1 ] && echo "would remove $DEST/$f" || { rm "$DEST/$f"; echo "removed $DEST/$f"; }
    fi
  done
  if [ "$DRY" -eq 0 ] && [ -f "$MANIFEST" ]; then rm "$MANIFEST"; fi
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

# Record what we installed, then verify every file actually landed.
printf '%s\n' $ROLES > "$MANIFEST"
want=$(echo $ROLES | wc -w | tr -d ' '); got=0
for f in $ROLES; do [ -f "$DEST/$f" ] && got=$((got+1)); done
if [ "$got" -ne "$want" ]; then
  echo "ERROR: expected $want files in $DEST but found $got — partial install, re-run." >&2
  exit 1
fi
echo "install done: $got roles in $DEST (manifest: $MANIFEST)"
echo "NOTE: open a NEW Claude Code session to load the roles (agent definitions are read at session start)."
