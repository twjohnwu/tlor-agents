#!/usr/bin/env bash
# install.sh — copy TLOR agent roles, skills, and rules into ~/.claude/
# (no plugin system needed).
# Usage: ./install.sh [--dry-run] [--force] [--uninstall] [--with-optional]
# Prefer the plugin route when possible:
#   /plugin marketplace add twjohnwu/tlor-agents   then   /plugin install tlor-agents@tlor
set -euo pipefail

: "${HOME:?HOME is not set — refusing to guess an install location}"
SRC="$(cd "$(dirname "$0")/agents" && pwd)"
SKILLS_SRC="$(cd "$(dirname "$0")/skills" && pwd)"
RULES_SRC="$(cd "$(dirname "$0")/rules" && pwd)"
DEST="$HOME/.claude/agents"
SKILLS_DEST="$HOME/.claude/skills"
RULES_DEST="$HOME/.claude/rules"
MANIFEST="$DEST/.tlor-manifest"
SKILLS_MANIFEST="$SKILLS_DEST/.tlor-manifest"
RULES_MANIFEST="$RULES_DEST/.tlor-manifest"
DRY=0; FORCE=0; UNINSTALL=0; WITH_OPTIONAL=0
for a in "$@"; do
  case "$a" in
    --dry-run) DRY=1;;
    --force) FORCE=1;;
    --uninstall) UNINSTALL=1;;
    --with-optional) WITH_OPTIONAL=1;;
    *) echo "unknown arg: $a" >&2; exit 1;;
  esac
done

ROLES=$(cd "$SRC" && ls ./*.md | sed 's|^\./||')
SKILLS=$(cd "$SKILLS_SRC" && ls -d */ | sed 's|/$||')
RULES=$(cd "$RULES_SRC" && ls ./*.md | sed 's|^\./||')
if [ "$WITH_OPTIONAL" -eq 1 ]; then
  RULES_OPT_SRC="$(cd "$(dirname "$0")/rules-optional" && pwd)"
  RULES_OPT=$(cd "$RULES_OPT_SRC" && ls ./*.md | sed 's|^\./||')
  RULES="$RULES $RULES_OPT"
fi

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

  if [ -f "$RULES_MANIFEST" ]; then REMOVE_RULES=$(cat "$RULES_MANIFEST"); else REMOVE_RULES=$RULES; fi
  for f in $REMOVE_RULES; do
    if [ -f "$RULES_DEST/$f" ]; then
      [ "$DRY" -eq 1 ] && echo "would remove $RULES_DEST/$f" || { rm "$RULES_DEST/$f"; echo "removed $RULES_DEST/$f"; }
    fi
  done
  if [ "$DRY" -eq 0 ] && [ -f "$RULES_MANIFEST" ]; then rm "$RULES_MANIFEST"; fi

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
for f in $RULES; do
  rule_src="$RULES_SRC/$f"
  [ -f "$rule_src" ] || rule_src="$RULES_OPT_SRC/$f"
  if [ -f "$RULES_DEST/$f" ] && ! cmp -s "$rule_src" "$RULES_DEST/$f"; then
    conflicts="$conflicts $f"
  fi
done
if [ -n "$conflicts" ] && [ "$FORCE" -ne 1 ]; then
  echo "ABORT: these already exist at $DEST, $SKILLS_DEST, or $RULES_DEST with different content:$conflicts" >&2
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

mkdir -p "$RULES_DEST"
for f in $RULES; do
  rule_src="$RULES_SRC/$f"
  [ -f "$rule_src" ] || rule_src="$RULES_OPT_SRC/$f"
  [ "$DRY" -eq 1 ] && echo "would install $RULES_DEST/$f" || { cp "$rule_src" "$RULES_DEST/$f"; echo "installed $RULES_DEST/$f"; }
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

printf '%s\n' $RULES > "$RULES_MANIFEST"
want_rules=$(echo $RULES | wc -w | tr -d ' '); got_rules=0
for f in $RULES; do [ -f "$RULES_DEST/$f" ] && got_rules=$((got_rules+1)); done
if [ "$got_rules" -ne "$want_rules" ]; then
  echo "ERROR: expected $want_rules rules in $RULES_DEST but found $got_rules — partial install, re-run." >&2
  exit 1
fi

echo "install done: $got roles in $DEST (manifest: $MANIFEST), $got_skills skills in $SKILLS_DEST (manifest: $SKILLS_MANIFEST), $got_rules rules in $RULES_DEST (manifest: $RULES_MANIFEST)"
echo "NOTE: open a NEW Claude Code session to load the roles and skills (both are read at session start)."

echo ""
echo "HOOKS: Hooks only work with plugin installation (not install.sh)."
echo "  If you need hooks (institution_guard, verify_gate), install via:"
echo "  claude plugin add twjohnwu/tlor-agents"

echo ""
echo "ROUTING: For rules to auto-load, set up CLAUDE.md routing."
echo "  Run /tlor-init in Claude Code to generate CLAUDE.md with routing."
