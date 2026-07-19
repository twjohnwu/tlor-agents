# Installation & ownership

[← Back to README](../../README.md)

## Two ways to use this

- **Lightweight** — just install the plugin. The nine roles become available
  in any NEW session after install (in an already-running session, run
  `/reload-plugins` first). Invoke them explicitly by name, or add the
  CLAUDE.md snippet in [roles.md](roles.md) for consistent dispatch — in
  our headless probes, descriptions alone did not reliably trigger automatic
  delegation, so the snippet is the recommended lightweight setup.
- **Full** — additionally run `/tlor-init`. This lays down the rules files,
  the `~/.claude/institution/` layout (see below), and CLAUDE.md/AGENTS.md
  routing so dispatch discipline is enforced automatically rather than
  relying on the model to remember to use the roles.

## Ownership model

- **Base rules are plugin-owned.** Every install/upgrade overwrites the
  required rule files unconditionally and stamps them with the plugin's
  `version` (the single source of truth — not a value baked into the shipped
  file). Don't hand-edit these; edits are lost on the next install.
- **`rules/customize/` is yours.** The installer creates it, may seed it with
  optional starter files on first install, and never overwrites anything
  already there afterward — this is the only place persistent local
  customization belongs.
- **Base files have zero user-writable sections.** All user additions —
  lessons, the skill-namespace-priority table, local patterns — live in
  `rules/customize/`, never in a base rule file, since anything appended
  there is wiped on the next unconditional overwrite.
- **`~/.claude/institution/` layout.** For user-level installs,
  `~/.claude/{agents,rules,hooks}` become symlinks into
  `~/.claude/institution/<name>/`. This is idempotent: already a symlink →
  left alone; a real directory already there → moved under `institution/`
  and symlinked (nothing is lost); missing → created fresh. The indirection
  means the plugin's overwrite-on-install semantics for base rules/hooks
  never fight with a directory you relocated or are backing up by hand.

## Install

### Option A — as a plugin (recommended)

```
/plugin marketplace add twjohnwu/tlor-orchestration
/plugin install tlor-orchestration@tlor
```

Updates: bump happens on our side via the `version` field; refresh with
`/plugin marketplace update tlor`.

### Updates

Update support requires the marketplace installation route (Option A):
`/plugin marketplace add twjohnwu/tlor-orchestration` then
`/plugin install tlor-orchestration@tlor`. Every release bumps
`.claude-plugin/plugin.json`'s `version` — per Claude Code's plugin docs,
pushing commits alone does not surface an update; only a version bump does,
and `/plugin marketplace update tlor` then pulls it. The `install.sh` plain-
copy route (Option B) has no update UI at all — re-running `install.sh`
overwrites base rules again, but there's no notification that a new version
exists; check the repo's releases/version badge yourself.

### Option B — plain copy

```bash
git clone https://github.com/twjohnwu/tlor-orchestration.git
cd tlor-orchestration && ./install.sh          # --dry-run / --force / --uninstall / --with-optional / --stdd-role=ALL / --install-hook
```

Copies agents to `~/.claude/agents/`, rules to `~/.claude/rules/`, hook
scripts to `~/.claude/hooks/`, and skills to `~/.claude/skills/`, setting up
the `~/.claude/institution/` symlink layout on first run (see Ownership
model above). Add `--with-optional` to include the optional rules installed
from `rules/customize/`. Records manifests for clean `--uninstall`. Hook
*activation* (env vars, `hooks.json` wiring) still needs the plugin route
(Option A) — `install.sh` only places the files.

**`--stdd-role=RD|PM|UIUX|ALL`** — opt-in install of the STDD workflow
skills (`stdd-skills/*`, non-autoload; see [skills.md](skills.md)). Only
`ALL` is implemented this round; `RD`/`PM`/`UIUX` print a deferred message
and install nothing. No flag → no STDD skills, unchanged from before this
flag existed.

**`--install-hook`** — opt-in install + `settings.json` registration of the
STDD test-file guard (`hooks/stdd_test_guard.py`). Default NOT installed.
**Honest caveat**: Claude Code reads PreToolUse hooks from `settings.json`
once, at session start — a resumed/continued session will NOT pick up a
hook registered mid-session. Verify this hook in a brand-new (non-resumed)
session only.

**Lightweight users** (plugin only, no `/tlor-init`): see the CLAUDE.md
snippet in [roles.md](roles.md) to get dispatch discipline without the full
rules install.

### Option C — /tlor-init (recommended after plugin install)

After installing via Option A, run `/tlor-init` in Claude Code for guided
setup: choose installation level, install rules, generate CLAUDE.md and
AGENTS.md routing, and optionally enable hooks.

Either way, **open a new Claude Code session afterwards** — agent definitions
are loaded at session start.
