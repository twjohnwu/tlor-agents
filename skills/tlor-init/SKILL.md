---
description: Initialize tlor-orchestration orchestration framework — install agents, rules, CLAUDE.md/AGENTS.md routing, and optional hooks
---

# /tlor-init — Orchestration Framework Setup

Initialize or upgrade the tlor-orchestration orchestration framework. Installs agent
roles, dispatch rules, CLAUDE.md/AGENTS.md routing, and optional guard hooks.

## Workflow

### Step 1: Detect existing installation

Scan for existing tlor-orchestration files:

```bash
# Check common locations for existing agents
for dir in ~/.claude/agents .claude/agents agents; do
  if [ -d "$dir" ] && ls "$dir"/rohirrim-outrider.md 2>/dev/null; then
    echo "Found existing installation at: $dir"
  fi
done
```

If found, compare `version:` frontmatter in each installed file against the
bundled versions in the plugin. List any files with version differences:

| File | Installed | Bundled | Action needed |
|------|-----------|---------|---------------|
| (name) | (local ver) | (plugin ver) | update/skip |

### Step 2: Choose installation level

Ask the user which installation level to use:

- **User level** (`~/.claude/`): agents at `~/.claude/agents/`, rules at
  `~/.claude/rules/`, CLAUDE.md at user root — available to ALL projects
- **Project level** (`.claude/`): agents at `.claude/agents/`, rules at
  `.claude/rules/`, CLAUDE.md at project root — scoped to this project
- **Repo level**: direct copy to user-specified paths — maximum flexibility

Do NOT cross-contaminate levels. User-level install does not touch project files.

### Step 3: Set up the institution layout and install agents

For a **User level** install only (`~/.claude/`), first make the layout
idempotent so this and future installs never clobber a directory the user
relocated by hand. Apply this 3-branch check to each of
`~/.claude/agents`, `~/.claude/rules`, `~/.claude/hooks`:

1. **Already a symlink** → skip, nothing to do.
2. **A real directory exists** → move it to `~/.claude/institution/<name>/`,
   then symlink `~/.claude/<name>` to it (so nothing already there is lost).
3. **Missing** → create `~/.claude/institution/<name>/` and symlink
   `~/.claude/<name>` to it.

(Project/repo level installs use plain directories — this institution layout
is a `~/.claude/` concept only.)

Then copy the 9 agent role definitions from the plugin's `agents/` directory
to `<target>/agents/`:

- rohirrim-outrider.md
- ranger-pathfinder.md
- noldor-loremaster.md
- dwarf-smith.md
- gondor-builder.md
- eagle-sentinel.md
- elf-archer.md
- orc-saboteur.md
- hobbit-gardener.md

If files already exist and have a LOWER version number, ask the user:
- **Overwrite**: backup to `.tlor-backup-YYYYMMDD/` then replace
- **Skip**: keep the existing version
- **View diff**: show the differences before deciding

If local version >= bundled version, skip automatically.

### Step 4: Install required rules

Base rules are **plugin-owned**: copy the 6 required rule files from the
plugin's `rules/` directory to `<target>/rules/` as an **unconditional
overwrite** — no version-compare-and-ask here, the plugin is the single
source of truth for these files. While copying, inject a `version: <plugin
version>` line into each file's frontmatter (reading the version from the
plugin's `.claude-plugin/plugin.json`, not from the shipped file itself).

- dispatch.md — role dispatch table, delegation rules, escalation paths,
  plan mode dispatch table requirements
- decomposition.md — how to split tasks into dispatches
- delegation-templates.md — fill-in prompt templates for subagent dispatch
- judgment.md — when to escalate, when done, when to ask
- risk-tiers.md — classify actions by risk before executing
- maintenance.md — what's safe to change vs needs user approval

None of these 6 files carry a `## Lessons` section of their own — they're
overwritten unconditionally on every upgrade, so anything appended there
would be wiped. Recurring workflow lessons instead go in
`rules/customize/lessons.md` (see Step 5).

### Step 5: Offer optional rules

Ask the user whether to install optional rules from `rules/customize/` in the
plugin bundle:

- **design-principles.md** — 7 fallback principles for uncovered cases (P1-P7)
- **user-decision-patterns.md** — 3 decision patterns for AI-assisted development (D1-D3)
- **customize/letter-to-future-sessions.md** — a blank template the user
  fills in over time (non-obvious project facts, decay countermeasures,
  honest limits); ships empty on purpose.
- **customize/skill-triggers.md** — when to invoke a skill instead of
  following a blanket "always invoke" injection; ships with a
  placeholder namespace-priority table. After installing, guide the user to
  fill it in with the plugins they actually have installed — that table
  can't be filled in generically at build time.
- **customize/lessons.md** — the append-only log for recurring workflow
  lessons, one `##` section per base rule file; ships with empty sections.

These provide design philosophy guidance. The framework works without them.
If installed, copy them to `<target>/rules/customize/`. Per the ownership
model below, only copy a file if it does not already exist at the
destination — never overwrite something already in `customize/`.

### Step 6: Create the customize directory

Ensure `<target>/rules/customize/` exists at the install destination:

- If Step 5 installed optional rules, this directory already exists — nothing
  further to do.
- If the user skipped Step 5, create the empty directory anyway.

This is the landing zone for the user's own project- or team-specific rules,
and the only place user content lives — **the installer never overwrites
anything already in `customize/`**, no matter how it got there (Step 5
optional copy, or the user's own files). Explain to the user: any `.md` file
placed in `rules/customize/` is picked up automatically by the routing
table's catch-all row (Step 7) — no further wiring needed, just drop the
file in.

### Step 7: Set up CLAUDE.md + AGENTS.md routing

Generate TWO files (replace `<rules-path>` with the actual path, e.g.
`.claude/rules` for project level).

**CLAUDE.md** (thin router, <20 lines):

```
@AGENTS.md

## Non-negotiable rules
1. Delegate, don't do. (→ rules/dispatch.md)
2. Verify before claiming done. (→ rules/dispatch.md §5)
3. Plan mode uses dispatch.md roles. (overrides built-in search default)
```

**AGENTS.md** (routing + agent priority):

```
# AGENTS.md — tlor-orchestration orchestration

## Agent routing priority
This environment uses tlor-orchestration roles as the PRIMARY dispatch targets.
If other plugins provide agents with similar functions, prefer tlor-orchestration
roles unless the user explicitly names another plugin's agent.

## Routing table
| Situation | Read first |
|---|---|
| Dispatching subagents, model/effort, escalation, verification | <rules-path>/dispatch.md |
| Splitting a task into dispatches | <rules-path>/decomposition.md |
| Writing a delegation prompt | <rules-path>/delegation-templates.md |
| Unsure: escalate? done? ask user? wrong direction? | <rules-path>/judgment.md |
| Classifying action risk before executing | <rules-path>/risk-tiers.md |
| Updating rules or instruction files | <rules-path>/maintenance.md |
| Deciding whether to invoke a skill | <rules-path>/customize/skill-triggers.md (if installed) |
| Project/team-specific conventions | <rules-path>/customize/ (scan all .md files) |
```

Handle CLAUDE.md and AGENTS.md as two SEPARATE existing-file checks:

- If neither exists: create both with the above content.
- If CLAUDE.md exists but AGENTS.md does not (or vice versa): create the
  missing one; for the existing one, apply the same append/replace/skip
  choice below.
- For each file that already exists, show the user the content that would
  be added and ask whether to:
  - **Append**: add the generated content to the existing file
  - **Replace**: overwrite with the generated content (backup first)
  - **Skip**: leave the file unchanged (warn that routing won't auto-load
    for that file)

### Step 8: Detect agent collisions

Scan `<target>/agents/` for all agent definitions (not just tlor-orchestration).
If agents from OTHER sources are found with overlapping functionality:

Report collisions:

| Agent | Source | Overlaps with |
|-------|--------|---------------|
| (name) | (plugin/source) | (tlor-orchestration role) |

The AGENTS.md routing table already declares tlor-orchestration as PRIMARY targets.
Remind the user that explicit routing in AGENTS.md is the only reliable way
to prevent namespace-based agent selection in multi-plugin environments.

### Step 9: Offer hooks (opt-in)

Present available hooks with clear descriptions:

1. **institution_guard** (PreToolUse): Blocks the main session from directly
   editing rules/CLAUDE.md/AGENTS.md files. Enforces "commander doesn't do
   field work" — edits must go through subagent dispatch. Subagents are
   always allowed through.
   - Activated by setting `TLOR_INSTITUTION_GUARD=1` in your environment
   - Python-first, bash fallback if Python 3 unavailable

2. **verify_gate** (Stop): Blocks turn completion when code files were edited
   but no test command was detected. Enforces fail-then-pass evidence.
   - Activated by setting `TLOR_VERIFY_GATE=1` in your environment
   - Requires Python 3

Let the user choose per-hook: install or skip. Do NOT install any hook without
explicit consent.

For hooks chosen: copy `hooks/institution_guard.py` and `hooks/verify_gate.py`
from the plugin bundle to `~/.claude/institution/hooks/` (this lands at
`~/.claude/hooks/` through the Step 3 symlink). Then explain that activation
is still via environment variables. Tell the user to add the relevant env
var to their shell profile:

```bash
# Add to ~/.zshrc or ~/.bashrc
export TLOR_INSTITUTION_GUARD=1  # Enable institution file guard
export TLOR_VERIFY_GATE=1        # Enable test verification gate
```

### Step 10: Report summary

Print installation summary:

```
tlor-orchestration initialization complete:
  Agents:    N installed (M updated, K skipped)
  Rules:     N installed (M updated, K skipped)
  Optional:  N installed (rules/customize/)
  CLAUDE.md: created / updated / skipped
  AGENTS.md: created / updated / skipped
  Hooks:     institution_guard (enabled/skipped), verify_gate (enabled/skipped)
  Backups:   .tlor-backup-YYYYMMDD/ (N files)
```

## Notes

- This skill is idempotent — safe to run multiple times
- Backups are stored in `.tlor-backup-YYYYMMDD/` at the target level
- Use `/tlor-restore` to rollback from a backup
- All files use semantic versioning (X.Y.Z) in frontmatter for upgrade detection
