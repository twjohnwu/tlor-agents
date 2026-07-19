#!/usr/bin/env bash
# install.sh — copy TLOR agent roles, skills, rules, and hooks into ~/.claude/
# (no plugin system needed).
# Usage: ./install.sh [--dry-run] [--force] [--uninstall] [--with-optional]
#                      [--stdd-role=RD|PM|UIUX|ALL] [--install-hook]
# Prefer the plugin route when possible:
#   /plugin marketplace add twjohnwu/tlor-orchestration   then   /plugin install tlor-orchestration@tlor
#
# --stdd-role=RD|PM|UIUX|ALL: opt-in install of the STDD workflow skills
#   (stdd-skills/*, non-autoload). Only ALL is implemented this round; RD/PM/
#   UIUX print a deferred message and install nothing (see
#   specs/stdd-integration.md S-33/S-35). No flag => no STDD skills, same as
#   before this flag existed.
# --install-hook: opt-in install + settings.json registration of the STDD
#   test-file guard (REQ-09). Default NOT installed. HONEST CAVEAT: Claude
#   Code reads PreToolUse hooks from settings.json once, at session start —
#   a resumed/continued session will NOT pick up a hook registered mid-
#   session. Verify this hook in a brand-new (non-resumed) session only.
set -euo pipefail

: "${HOME:?HOME is not set — refusing to guess an install location}"
ROOT="$(cd "$(dirname "$0")" && pwd)"
SRC="$ROOT/agents"
SKILLS_SRC="$ROOT/skills"
RULES_SRC="$ROOT/rules"
HOOKS_SRC="$ROOT/hooks"
STDD_SKILLS_SRC="$ROOT/stdd-skills"
PLUGIN_JSON="$ROOT/.claude-plugin/plugin.json"

INSTITUTION="$HOME/.claude/institution"
DEST="$HOME/.claude/agents"
SKILLS_DEST="$HOME/.claude/skills"
RULES_DEST="$HOME/.claude/rules"
HOOKS_DEST="$HOME/.claude/hooks"
SETTINGS_JSON="$HOME/.claude/settings.json"
MANIFEST="$DEST/.tlor-manifest"
SKILLS_MANIFEST="$SKILLS_DEST/.tlor-manifest"
RULES_MANIFEST="$RULES_DEST/.tlor-manifest"
HOOKS_MANIFEST="$HOOKS_DEST/.tlor-manifest"
STDD_MANIFEST="$SKILLS_DEST/.tlor-stdd-manifest"

DRY=0; FORCE=0; UNINSTALL=0; WITH_OPTIONAL=0; STDD_ROLE=""; INSTALL_HOOK=0
for a in "$@"; do
  case "$a" in
    --dry-run) DRY=1;;
    --force) FORCE=1;;
    --uninstall) UNINSTALL=1;;
    --with-optional) WITH_OPTIONAL=1;;
    --stdd-role=*) STDD_ROLE="${a#*=}";;
    --install-hook) INSTALL_HOOK=1;;
    *) echo "unknown arg: $a" >&2; exit 1;;
  esac
done

case "$STDD_ROLE" in
  ""|RD|PM|UIUX|ALL) ;;
  *) echo "unknown --stdd-role value: $STDD_ROLE (expected RD|PM|UIUX|ALL)" >&2; exit 1;;
esac

# S-33 profile table (config-driven, per specs/stdd-integration.md S-33):
# maps a 視角 to its STDD skill dir subset. RD/PM/UIUX subsets are recorded
# here for a future implementation session but are NOT installed this round
# (deferred, D5) — `install.sh` currently only implements ALL, and prints a
# deferred message for RD/PM/UIUX instead of installing their subset. ALL's
# list is discovered dynamically from stdd-skills/*/ rather than hardcoded,
# so a future 8th skill needs no change here.
stdd_profile_skills() {
  case "$1" in
    RD)   echo "stdd-plan stdd-execute stdd stdd-lint" ;;
    PM)   echo "stdd-explore stdd-spec stdd stdd-lint" ;;
    UIUX) echo "stdd-explore stdd-uiux stdd stdd-lint" ;;
    ALL)  (cd "$STDD_SKILLS_SRC" && ls -d */ | sed 's|/$||') ;;
    *)    echo "" ;;
  esac
}

# Single source of truth for the version stamped into every base rule file's
# frontmatter — read directly from plugin.json, no jq dependency.
VERSION=$(grep -m1 '"version"' "$PLUGIN_JSON" | sed -E 's/.*"version": *"([^"]+)".*/\1/')

ROLES=$(cd "$SRC" && ls ./*.md | sed 's|^\./||')
SKILLS=$(cd "$SKILLS_SRC" && ls -d */ | sed 's|/$||')
RULES=$(cd "$RULES_SRC" && ls ./*.md | sed 's|^\./||')
HOOK_FILES="institution_guard.py verify_gate.py"
CUSTOMIZE_SRC="$RULES_SRC/customize"
CUSTOMIZE_FILES=""
if [ "$WITH_OPTIONAL" -eq 1 ]; then
  CUSTOMIZE_FILES=$(cd "$CUSTOMIZE_SRC" && ls ./*.md 2>/dev/null | sed 's|^\./||')
fi

# Idempotent institution layout: ~/.claude/{agents,rules,hooks} become
# symlinks into ~/.claude/institution/<name>, so this plugin's overwrite-on-
# install semantics for base rules/hooks never clobber a directory the user
# relocated or is backing up by hand. Three branches per path:
#   already a symlink        -> skip
#   a real directory exists  -> move it under institution/<name>, then symlink
#   missing                  -> create institution/<name>, then symlink
ensure_institution_symlink() {
  local name="$1"
  local target="$HOME/.claude/$name"
  local real="$INSTITUTION/$name"
  if [ -L "$target" ]; then
    echo "institution: $target already a symlink — skip"
  elif [ -e "$target" ]; then
    if [ "$DRY" -eq 1 ]; then
      echo "would move $target -> $real and symlink"
    else
      mkdir -p "$INSTITUTION"
      mv "$target" "$real"
      ln -s "$real" "$target"
      echo "institution: moved $target -> $real, symlinked"
    fi
  else
    if [ "$DRY" -eq 1 ]; then
      echo "would create $real and symlink $target"
    else
      mkdir -p "$real"
      ln -s "$real" "$target"
      echo "institution: created $real, symlinked $target"
    fi
  fi
}

# Inject `version: X.Y.Z` (from plugin.json) into a rule file's frontmatter —
# replaces an existing `version:` line if present, otherwise inserts one
# before the closing `---`. This is the only place a base rule file's
# version comes from; the shipped file itself is not authoritative.
inject_version() {
  local file="$1"
  awk -v ver="$VERSION" '
    NR==1 && $0=="---" { print; infm=1; next }
    infm && /^version:/ { print "version: " ver; done=1; next }
    infm && $0=="---" { if (!done) print "version: " ver; print; infm=0; next }
    { print }
  ' "$file" > "$file.tmp.$$" && mv "$file.tmp.$$" "$file"
}

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
  # Clean up empty customize dir
  [ -d "$RULES_DEST/customize" ] && rmdir "$RULES_DEST/customize" 2>/dev/null || true
  if [ "$DRY" -eq 0 ] && [ -f "$RULES_MANIFEST" ]; then rm "$RULES_MANIFEST"; fi

  if [ -f "$HOOKS_MANIFEST" ]; then REMOVE_HOOKS=$(cat "$HOOKS_MANIFEST"); else REMOVE_HOOKS=$HOOK_FILES; fi
  for f in $REMOVE_HOOKS; do
    if [ -f "$HOOKS_DEST/$f" ]; then
      [ "$DRY" -eq 1 ] && echo "would remove $HOOKS_DEST/$f" || { rm "$HOOKS_DEST/$f"; echo "removed $HOOKS_DEST/$f"; }
    fi
  done
  if [ "$DRY" -eq 0 ] && [ -f "$HOOKS_MANIFEST" ]; then rm "$HOOKS_MANIFEST"; fi

  # STDD skills: only remove what our own manifest recorded (never guesses
  # at a subset — the first line is `role=<...>`, the rest are skill dirs).
  if [ -f "$STDD_MANIFEST" ]; then
    for s in $(tail -n +2 "$STDD_MANIFEST"); do
      if [ -d "$SKILLS_DEST/$s" ]; then
        [ "$DRY" -eq 1 ] && echo "would remove STDD skill $SKILLS_DEST/$s" || { rm -rf "$SKILLS_DEST/$s"; echo "removed STDD skill $SKILLS_DEST/$s"; }
      fi
    done
    if [ "$DRY" -eq 0 ]; then rm "$STDD_MANIFEST"; fi
  fi

  # STDD test-file guard hook: remove the copied script only. Un-registering
  # the settings.json entry is left to the user (rewriting someone else's
  # settings.json on uninstall without an explicit ask is a T2 action this
  # script does not take unprompted — see hooks/register_stdd_hook.py note).
  if [ -f "$HOOKS_DEST/stdd_test_guard.py" ]; then
    [ "$DRY" -eq 1 ] && echo "would remove $HOOKS_DEST/stdd_test_guard.py" || { rm "$HOOKS_DEST/stdd_test_guard.py"; echo "removed $HOOKS_DEST/stdd_test_guard.py (settings.json entry left in place — remove it by hand)"; }
  fi

  # Institution layout and its symlinks are left in place on uninstall —
  # unwinding a relocated real directory safely needs a decision only the
  # user can make; use /tlor-restore or undo it by hand.
  if [ "$DRY" -eq 1 ]; then echo "uninstall dry-run done (nothing removed)."; else echo "uninstall done."; fi
  exit 0
fi

for n in agents rules hooks; do
  ensure_institution_symlink "$n"
done

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

# Base rules are plugin-owned: unconditional overwrite, version stamped from
# plugin.json. Never touches rules/customize/ — that's the user's landing
# zone, handled separately below.
mkdir -p "$RULES_DEST"
for f in $RULES; do
  if [ "$DRY" -eq 1 ]; then
    echo "would install $RULES_DEST/$f (version $VERSION)"
  else
    cp "$RULES_SRC/$f" "$RULES_DEST/$f"
    inject_version "$RULES_DEST/$f"
    echo "installed $RULES_DEST/$f (version $VERSION)"
  fi
done

mkdir -p "$RULES_DEST/customize"
if [ -n "$CUSTOMIZE_FILES" ]; then
  for f in $CUSTOMIZE_FILES; do
    if [ -f "$RULES_DEST/customize/$f" ]; then
      echo "skipped $RULES_DEST/customize/$f (already exists — customize/ is never overwritten)"
    elif [ "$DRY" -eq 1 ]; then
      echo "would install $RULES_DEST/customize/$f"
    else
      cp "$CUSTOMIZE_SRC/$f" "$RULES_DEST/customize/$f"
      echo "installed $RULES_DEST/customize/$f"
    fi
  done
fi

# Hooks are plugin-owned scripts: unconditional overwrite, no frontmatter to
# stamp a version into.
mkdir -p "$HOOKS_DEST"
for f in $HOOK_FILES; do
  if [ -f "$HOOKS_SRC/$f" ]; then
    [ "$DRY" -eq 1 ] && echo "would install $HOOKS_DEST/$f" || { cp "$HOOKS_SRC/$f" "$HOOKS_DEST/$f"; echo "installed $HOOKS_DEST/$f"; }
  fi
done

# STDD skills: opt-in, --stdd-role=RD|PM|UIUX|ALL (no flag → install nothing,
# backward compatible — specs/stdd-integration.md S-35). Only ALL is
# implemented this round; RD/PM/UIUX print the deferred message and install
# nothing (no silent subset — S-33/S-35).
if [ -n "$STDD_ROLE" ]; then
  case "$STDD_ROLE" in
    RD|PM|UIUX)
      echo "此視角（${STDD_ROLE}）deferred，本輪僅支援 ALL（specs/stdd-integration.md S-33/S-35）——未安裝任何 STDD skill。"
      ;;
    ALL)
      STDD_SKILLS=$(stdd_profile_skills ALL)
      mkdir -p "$SKILLS_DEST"
      for s in $STDD_SKILLS; do
        if [ "$DRY" -eq 1 ]; then
          echo "would install STDD skill $SKILLS_DEST/$s"
        else
          mkdir -p "$SKILLS_DEST/$s"
          cp -r "$STDD_SKILLS_SRC/$s"/. "$SKILLS_DEST/$s"/
          echo "installed STDD skill $SKILLS_DEST/$s"
        fi
      done
      if [ "$DRY" -eq 0 ]; then
        { echo "role=ALL"; printf '%s\n' $STDD_SKILLS; } > "$STDD_MANIFEST"
        echo "recorded STDD role ALL in $STDD_MANIFEST"
      fi
      ;;
  esac
fi

# STDD test-file guard hook: independent of --stdd-role (S-35). Default NOT
# installed; only registers when --install-hook is explicitly passed.
if [ "$INSTALL_HOOK" -eq 1 ]; then
  if [ "$DRY" -eq 1 ]; then
    echo "would install $HOOKS_DEST/stdd_test_guard.py and register its PreToolUse entry in $SETTINGS_JSON"
  else
    cp "$HOOKS_SRC/stdd_test_guard.py" "$HOOKS_DEST/stdd_test_guard.py"
    echo "installed $HOOKS_DEST/stdd_test_guard.py"
    if command -v python3 >/dev/null 2>&1; then
      python3 "$HOOKS_SRC/register_stdd_hook.py" "$SETTINGS_JSON" "$HOOKS_DEST/stdd_test_guard.py"
    else
      echo "WARNING: python3 not found — could not auto-register the hook in $SETTINGS_JSON." >&2
      echo "  Add manually: PreToolUse -> command: python3 \"$HOOKS_DEST/stdd_test_guard.py\"" >&2
    fi
    echo "NOTE: PreToolUse hooks are snapshotted at session start. If this install"
    echo "  ran inside an existing (or --continue/--resume'd) session, the hook will"
    echo "  NOT be active there — verify it in a brand-new session, not a resumed one."
  fi
fi

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

ALL_RULES="$RULES"
for f in $CUSTOMIZE_FILES; do ALL_RULES="$ALL_RULES customize/$f"; done
printf '%s\n' $ALL_RULES > "$RULES_MANIFEST"
want_rules=$(echo $ALL_RULES | wc -w | tr -d ' '); got_rules=0
for f in $RULES; do [ -f "$RULES_DEST/$f" ] && got_rules=$((got_rules+1)); done
for f in $CUSTOMIZE_FILES; do [ -f "$RULES_DEST/customize/$f" ] && got_rules=$((got_rules+1)); done
if [ "$got_rules" -ne "$want_rules" ]; then
  echo "ERROR: expected $want_rules rules in $RULES_DEST but found $got_rules — partial install, re-run." >&2
  exit 1
fi

printf '%s\n' $HOOK_FILES > "$HOOKS_MANIFEST"
want_hooks=$(echo $HOOK_FILES | wc -w | tr -d ' '); got_hooks=0
for f in $HOOK_FILES; do [ -f "$HOOKS_DEST/$f" ] && got_hooks=$((got_hooks+1)); done
if [ "$got_hooks" -ne "$want_hooks" ]; then
  echo "ERROR: expected $want_hooks hooks in $HOOKS_DEST but found $got_hooks — partial install, re-run." >&2
  exit 1
fi

echo "install done: $got roles in $DEST (manifest: $MANIFEST), $got_skills skills in $SKILLS_DEST (manifest: $SKILLS_MANIFEST), $got_rules rules in $RULES_DEST (manifest: $RULES_MANIFEST), $got_hooks hooks in $HOOKS_DEST (manifest: $HOOKS_MANIFEST)"
echo "NOTE: open a NEW Claude Code session to load the roles and skills (both are read at session start)."

echo ""
echo "HOOKS: institution_guard.py and verify_gate.py are now copied to $HOOKS_DEST."
echo "  They still need wiring into a hooks.json (PreToolUse/Stop) and the"
echo "  TLOR_INSTITUTION_GUARD / TLOR_VERIFY_GATE env vars to activate — the"
echo "  plugin route (claude plugin add twjohnwu/tlor-orchestration) wires this"
echo "  automatically; install.sh only places the files."

echo ""
echo "ROUTING: For rules to auto-load, set up CLAUDE.md + AGENTS.md routing."
echo "  Run /tlor-init in Claude Code to generate CLAUDE.md and AGENTS.md with routing."
