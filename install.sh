#!/usr/bin/env bash
# install.sh — copy the TLOR agent roles into ~/.claude/agents/ and the
# adversarial-review skill into ~/.claude/skills/ (no plugin system needed).
# Usage: ./install.sh [--dry-run] [--force] [--uninstall]
# Prefer the plugin route when possible:
#   /plugin marketplace add twjohnwu/tlor-agents   then   /plugin install tlor-agents@tlor
set -euo pipefail

: "${HOME:?HOME is not set — refusing to guess an install location}"
SRC="$(cd "$(dirname "$0")/agents" && pwd)"
SKILLS_SRC="$(cd "$(dirname "$0")/skills" && pwd)"
DEST="$HOME/.claude/agents"
SKILLS_DEST="$HOME/.claude/skills"
MANIFEST="$DEST/.tlor-manifest"
SKILLS_MANIFEST="$SKILLS_DEST/.tlor-manifest"
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
SKILLS=$(cd "$SKILLS_SRC" && ls -d */ | sed 's|/$||')

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

  if [ -f "$SKILLS_MANIFEST" ]; then REMOVE_SKILLS=$(cat "$SKILLS_MANIFEST"); else REMOVE_SKILLS=$SKILLS; fi
  for s in $REMOVE_SKILLS; do
    if [ -d "$SKILLS_DEST/$s" ]; then
      [ "$DRY" -eq 1 ] && echo "would remove $SKILLS_DEST/$s" || { rm -rf "$SKILLS_DEST/$s"; echo "removed $SKILLS_DEST/$s"; }
    fi
  done
  if [ "$DRY" -eq 0 ] && [ -f "$SKILLS_MANIFEST" ]; then rm "$SKILLS_MANIFEST"; fi

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
for s in $SKILLS; do
  if [ -d "$SKILLS_DEST/$s" ] && ! diff -rq "$SKILLS_SRC/$s" "$SKILLS_DEST/$s" >/dev/null 2>&1; then
    conflicts="$conflicts $s"
  fi
done
if [ -n "$conflicts" ] && [ "$FORCE" -ne 1 ]; then
  echo "ABORT: these already exist at $DEST or $SKILLS_DEST with different content:$conflicts" >&2
  echo "Re-run with --force to overwrite, or remove them first." >&2
  exit 1
fi

for f in $ROLES; do
  [ "$DRY" -eq 1 ] && echo "would install $DEST/$f" || { cp "$SRC/$f" "$DEST/$f"; echo "installed $DEST/$f"; }
done

mkdir -p "$SKILLS_DEST"
for s in $SKILLS; do
  if [ "$DRY" -eq 1 ]; then
    for sf in "$SKILLS_SRC/$s"/*; do echo "would install $SKILLS_DEST/$s/$(basename "$sf")"; done
  else
    mkdir -p "$SKILLS_DEST/$s"
    cp -r "$SKILLS_SRC/$s"/. "$SKILLS_DEST/$s"/
    echo "installed $SKILLS_DEST/$s"
  fi
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

printf '%s\n' $SKILLS > "$SKILLS_MANIFEST"
want_skills=$(echo $SKILLS | wc -w | tr -d ' '); got_skills=0
for s in $SKILLS; do [ -d "$SKILLS_DEST/$s" ] && got_skills=$((got_skills+1)); done
if [ "$got_skills" -ne "$want_skills" ]; then
  echo "ERROR: expected $want_skills skills in $SKILLS_DEST but found $got_skills — partial install, re-run." >&2
  exit 1
fi

echo "install done: $got roles in $DEST (manifest: $MANIFEST), $got_skills skills in $SKILLS_DEST (manifest: $SKILLS_MANIFEST)"
echo "NOTE: open a NEW Claude Code session to load the roles and skills (both are read at session start)."
