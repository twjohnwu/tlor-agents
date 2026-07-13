---
description: Initialize tlor-agents orchestration framework — install agents, rules, CLAUDE.md routing, and optional hooks
---

# /tlor-init — Orchestration Framework Setup

Initialize or upgrade the tlor-agents orchestration framework. Installs agent
roles, dispatch rules, CLAUDE.md routing, and optional guard hooks.

## Workflow

### Step 1: Detect existing installation

Scan for existing tlor-agents files:

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

### Step 3: Install agents

Copy the 9 agent role definitions from the plugin's `agents/` directory to
`<target>/agents/`:

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

Copy 6 required rule files from the plugin's `rules/` directory to
`<target>/rules/`:

- dispatch.md — role dispatch table, delegation rules, escalation paths,
  plan mode dispatch table requirements
- decomposition.md — how to split tasks into dispatches
- delegation-templates.md — fill-in prompt templates for subagent dispatch
- judgment.md — when to escalate, when done, when to ask
- risk-tiers.md — classify actions by risk before executing
- maintenance.md — what's safe to change vs needs user approval

Same version-check and backup logic as Step 3.

### Step 5: Offer optional rules

Ask the user whether to install optional rules from `rules-optional/`:

- **design-principles.md** — 7 fallback principles for uncovered cases (P1-P7)
- **user-decision-patterns.md** — 3 decision patterns for AI-assisted development (D1-D3)

These provide design philosophy guidance. The framework works without them.

### Step 6: Set up CLAUDE.md routing

Generate a CLAUDE.md file with the following content (replace `<rules-path>`
with the actual path, e.g. `.claude/rules` for project level).

The CLAUDE.md should contain:
- An agent routing priority section declaring tlor-agents as PRIMARY targets
- Three non-negotiable rules: delegate don't do, verify before done, plan mode uses dispatch roles
- A routing table pointing to each installed rule file

If no CLAUDE.md exists: create it with the above content.

If CLAUDE.md already exists: show the user the routing additions that would
be added and ask whether to:
- **Append**: add the routing table to the existing CLAUDE.md
- **Replace**: overwrite with the generated content (backup first)
- **Skip**: leave CLAUDE.md unchanged (warn that rules won't auto-load)

### Step 7: Detect agent collisions

Scan `<target>/agents/` for all agent definitions (not just tlor-agents).
If agents from OTHER sources are found with overlapping functionality:

Report collisions:

| Agent | Source | Overlaps with |
|-------|--------|---------------|
| (name) | (plugin/source) | (tlor-agents role) |

The dispatch.md routing table already declares tlor-agents as PRIMARY targets.
Remind the user that explicit routing in CLAUDE.md is the only reliable way
to prevent namespace-based agent selection in multi-plugin environments.

### Step 8: Offer hooks (opt-in)

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

For hooks chosen: explain that the hooks are bundled with the plugin and
activated via environment variables. Tell the user to add the relevant
env var to their shell profile:

```bash
# Add to ~/.zshrc or ~/.bashrc
export TLOR_INSTITUTION_GUARD=1  # Enable institution file guard
export TLOR_VERIFY_GATE=1        # Enable test verification gate
```

### Step 9: Report summary

Print installation summary:

```
tlor-agents initialization complete:
  Agents:    N installed (M updated, K skipped)
  Rules:     N installed (M updated, K skipped)
  Optional:  N installed
  CLAUDE.md: created / updated / skipped
  Hooks:     institution_guard (enabled/skipped), verify_gate (enabled/skipped)
  Backups:   .tlor-backup-YYYYMMDD/ (N files)
```

## Notes

- This skill is idempotent — safe to run multiple times
- Backups are stored in `.tlor-backup-YYYYMMDD/` at the target level
- Use `/tlor-restore` to rollback from a backup
- All files use semantic versioning (X.Y.Z) in frontmatter for upgrade detection
