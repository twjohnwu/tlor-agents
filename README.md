# TLOR Agents — a Middle-earth fellowship for Claude Code

[![CI](https://github.com/twjohnwu/tlor-agents/actions/workflows/validate.yml/badge.svg)](https://github.com/twjohnwu/tlor-agents/actions/workflows/validate.yml)
[![version](https://img.shields.io/badge/version-2.0.0-blue)](https://github.com/twjohnwu/tlor-agents/blob/main/.claude-plugin/plugin.json)
[![license](https://img.shields.io/badge/license-MIT-green)](LICENSE)

An orchestration framework for [Claude Code](https://code.claude.com), themed
on Middle-earth. Nine pinned subagent roles with fixed model/effort/tools,
plus dispatch rules, setup skills, and opt-in guard hooks — everything an AI
coding session needs to delegate reliably.

繁體中文說明請見 [README.zh-TW.md](README.zh-TW.md).

## The worldview

- **You (the engineer) are Ilúvatar** — the source of intent.
- **The main Claude session is a Maia** — it interprets your will, convenes
  the fellowship, and dispatches the races. It does not do field work itself.
- **Subagents are the peoples of Middle-earth** — each born with a fixed fate
  (frontmatter): what model it runs on, how hard it thinks, which tools it
  may touch.

## The fellowship

| Role | Race & post | Model / effort | Duty |
|---|---|---|---|
| `rohirrim-outrider` | Rohirrim outrider | haiku / low | Fast, cheap, targeted lookup: "where is X / how does Y work" |
| `ranger-pathfinder` | Ranger of the North | sonnet / low | Broad, thorough read-only sweep when a miss is costly |
| `noldor-loremaster` | Noldorin loremaster | sonnet / medium | Web/docs research with sources and versions; fact vs inference |
| `dwarf-smith` | Dwarven smith | sonnet / low | Fully-specified mechanical work; never improvises |
| `gondor-builder` | Mason of Gondor | sonnet / medium | Implements a clear spec with local judgment; design stays with the Maia |
| `eagle-sentinel` | Great Eagle | opus / medium | Fresh-context adversarial verification; CONFIRMED/REFUTED |
| `elf-archer` | Elven archer | opus / medium | Correctness lens: every arrow pins one logical flaw |
| `orc-saboteur` | Orc saboteur | opus / medium | Security & failure-mode lens: input validation, races, partial failure |
| `hobbit-gardener` | Hobbit gardener | opus / medium | Simplicity lens: prunes over-engineering |

The last three form the **adversarial review panel**: for high-risk verdicts
`eagle-sentinel` recommends it, and the Maia convenes it (≥3 independent
lenses + a judge). For routine or borderline convenings, pass an explicit
`model: sonnet` downgrade when dispatching the lenses — a per-call override beats the
role's pinned frontmatter.

## Skills

| Skill | Purpose |
|---|---|
| `/rivendell-council` | Convene the adversarial panel (3 lenses, majority-survival verdict) |
| `/tlor-init` | Install agents + rules + CLAUDE.md routing + optional hooks |
| `/tlor-restore` | Rollback to a previous installation from backup |

**rivendell-council** — the convening procedure for the adversarial panel:
assemble a self-contained review package, dispatch the three lenses in
parallel, resolve by majority-survival verdict, and loop until dry for
critical conclusions.

**tlor-init** — one-time setup skill that installs the full framework:
choose installation level (user/project/repo), copy agents and rules,
generate CLAUDE.md routing, optionally enable hooks. Detects existing
installations and offers upgrade with backup.

**tlor-restore** — rollback from backups created by `/tlor-init` during
upgrades.

**Triggering.** Auto-invocation of `/rivendell-council` is description-driven
— the model matches the skill description's trigger words against the
situation. For a hard guarantee, add one line to your project's `CLAUDE.md`:

```
High-risk verdicts (irreversible ops, contract/schema changes, money/precision, architecture decisions, root-cause claims, production-affecting conclusions) MUST pass /tlor-agents:rivendell-council before adoption.
```

`eagle-sentinel`'s HIGH-RISK recommendation is the convening signal.

## Rules

The plugin bundles depersonalized orchestration rules — install them via
`/tlor-init` or `install.sh`:

**Required** (6 files):

| Rule | Purpose |
|---|---|
| `dispatch.md` | Role dispatch table, delegation contract, escalation paths, verification rules |
| `decomposition.md` | How to split tasks into dispatches (parallel vs sequential, sizing) |
| `delegation-templates.md` | Fill-in prompt templates for each dispatch type |
| `judgment.md` | When to escalate, when done, when to ask, wrong-direction signals |
| `risk-tiers.md` | Classify actions by risk (T1 irreversible / T2 hard-to-undo / T3 reversible) |
| `maintenance.md` | What sessions may change vs what needs human approval |

**Optional** (2 files — install with `--with-optional` or choose in `/tlor-init`):

| Rule | Purpose |
|---|---|
| `design-principles.md` | 7 fallback principles for uncovered cases (P1-P7) |
| `user-decision-patterns.md` | 3 decision patterns for AI-assisted development (D1-D3) |

## Hooks (opt-in)

Both hooks are **OFF by default** — enable via environment variables.
Plugin installs only: `install.sh` does not wire hooks.

### institution_guard (PreToolUse)

Blocks the main session from directly editing rules/CLAUDE.md/AGENTS.md
files — enforces "the commander doesn't do field work." Subagent edits
pass through. Python-first with bash fallback.

Enable: `export TLOR_INSTITUTION_GUARD=1`

### verify_gate (Stop)

Catches "done" claims with no evidence: if code files were edited this turn
and no test command was run, it blocks the turn once, asking for fail-then-pass
evidence. Fails open on any internal error.

Enable: `export TLOR_VERIFY_GATE=1`

## Install

### Option A — as a plugin (recommended)

```
/plugin marketplace add twjohnwu/tlor-agents
/plugin install tlor-agents@tlor
```

Updates: bump happens on our side via the `version` field; refresh with
`/plugin marketplace update tlor`.

### Option B — plain copy

```bash
git clone https://github.com/twjohnwu/tlor-agents.git
cd tlor-agents && ./install.sh          # --dry-run / --force / --uninstall / --with-optional
```

Copies agents to `~/.claude/agents/`, rules to `~/.claude/rules/`, and skills
to `~/.claude/skills/`. Add `--with-optional` to include the optional rules.
Records manifests for clean `--uninstall`. Hooks are not wired — use the
plugin route (Option A) for hooks.

### Option C — /tlor-init (recommended after plugin install)

After installing via Option A, run `/tlor-init` in Claude Code for guided
setup: choose installation level, install rules, generate CLAUDE.md routing,
and optionally enable hooks.

Either way, **open a new Claude Code session afterwards** — agent definitions
are loaded at session start.

## Notes

- **Serena tools are optional.** The two search roles list
  [Serena](https://github.com/oraios/serena) semantic tools in `tools`; if you
  don't have the plugin, the roles fall back to Grep/Glob (instructions say so).
- **Hard rules slot**: `eagle-sentinel` treats caller-supplied "Hard Rules"
  (non-negotiable house conventions pasted into its prompt) as auto-FAIL on
  violation. Paste yours when dispatching.
- Model names (`haiku`/`sonnet`/`opus`) follow the Agent tool's accepted
  values; edit the frontmatter if your environment differs. The rules use
  tier-based language (cheap/mid-tier/top-tier) so they stay portable even as
  agent frontmatter keeps specific model names.

## Limits (honest notes)

- **"Read-only" is behavioral for Bash-carrying roles.** `eagle-sentinel`,
  `elf-archer`, `orc-saboteur`, `rohirrim-outrider` and `ranger-pathfinder` hold Bash to run tests/inspection; Bash can
  technically write, so their never-edits stance is an instruction, not a sandbox.
  `hobbit-gardener` is the one panel role that is read-only at the tool level.
- **Unavailable model → silent fallback.** Per official docs, a `model:` value
  your org excludes makes the subagent run on the inherited session model
  instead — no error. If you have no opus access, `eagle-sentinel` quietly
  runs on your session's model.
- **Security-lens roles may trip a model's safety filter.** `orc-saboteur`
  (and to a lesser degree `elf-archer`) do adversarial *defensive* review; on
  some models a broad safety classifier may read that as offensive-security
  work and auto-switch models mid-task. It's a known false positive — the
  review still completes. Wording is kept defensive to minimize it.

## Releasing (maintainers)

Before publishing changes: `claude plugin validate . --strict` (validates
plugin.json + agent frontmatter), test locally with
`claude --plugin-dir .`, then bump `version` in `.claude-plugin/plugin.json` —
users only receive updates when the version changes.

## License & homage

MIT © [twjohnwu](https://github.com/twjohnwu). A fan homage to
J.R.R. Tolkien's legendarium; not affiliated with or endorsed by the Tolkien
Estate or Middle-earth Enterprises. Race and role names are used
thematically. The rivendell-council convening flow is inspired by, and the
verify-gate hook is adapted from,
[Miguok/fable-harness](https://github.com/Miguok/fable-harness) (MIT).
