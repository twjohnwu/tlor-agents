# Skills

[← Back to README](../../README.md)

See the README's skill routing table for the quick reference. This page
covers detail beyond that table plus the STDD opt-in explanation.

## Autoloaded skills — detail

**rivendell-council** — the convening procedure for the adversarial panel:
assemble a self-contained review package, dispatch the three lenses in
parallel, resolve by majority-survival verdict, and loop until dry for
critical conclusions.

**tlor-init** — one-time setup skill that installs the full framework:
choose installation level (user/project/repo), copy agents and rules,
generate CLAUDE.md and AGENTS.md routing, optionally enable hooks. Detects
existing installations and offers upgrade with backup. Also offers the STDD
opt-in step (see below).

**tlor-restore** — rollback from backups created by `/tlor-init` during
upgrades.

**erebor-ledger** — reads existing Claude Code transcripts and reports how
much dispatching to tlor roles saved versus running the same work inline on
the orchestrator model. Retrospective only; not a live estimator for a
single in-progress dispatch.

## Opt-in: STDD workflow skills

Installed via `install.sh --stdd-role=ALL` or `/tlor-init`'s STDD step.

Not autoloaded — these seven skills implement the Spec-driven Test-Driven
Development pipeline and only land in `~/.claude/skills/` when explicitly
requested. This round only the `ALL` profile is implemented; `RD`/`PM`/`UIUX`
role-scoped subsets are deferred (`install.sh --stdd-role=RD|PM|UIUX` prints
a deferred message and installs nothing).

| Skill | Middle-earth title | Purpose | When to invoke |
|---|---|---|---|
| `/stdd` | Palantír 真知晶石 | Read-only status dashboard: reports which STDD stage a change is in, re-verifies the fingerprint, suggests the next command | Checking progress on an in-flight STDD change |
| `/stdd-explore` | Lore 智者探詢 | Thinking-partner phase that clarifies a vague feature idea before any spec is written | Starting a new STDD change from a rough idea |
| `/stdd-uiux` | Lórien 精靈美學 | Conditional design phase; generates `design-ux.md` | Only when the change has a user-facing UI surface |
| `/stdd-spec` | Oath 遠征誓約 | Writes a GWT-format `spec.md` with test-mapping/verification-command fields, self-reviews via `/stdd-lint`, and gates on adversarial-panel approval | Writing or approving a spec for an STDD change |
| `/stdd-plan` | Map 行軍圖 | Generates condition-based `design-be.md`/`design-fe.md`/`api.yml` and a scenario-covered `tasks.md` from an approved spec | Turning an approved spec into a design + task list |
| `/stdd-execute` | Forge 鑄造 | Runs the per-task RED → GREEN → REFACTOR loop against an approved `tasks.md`, two-dispatch model with an independent verifier | Implementing STDD tasks one at a time |
| `/stdd-lint` | Eagle Vision 鷹之視野 | Pure rule-based (non-model-judgment) mechanical checker: placeholder leakage, ID continuity, GWT completeness, test-mapping/coverage, fingerprint state | Called internally by stdd-spec/stdd-plan/stdd-execute's boundary checks, and directly by the user |

Pipeline order: `stdd-explore → stdd-uiux (conditional) → stdd-spec →
stdd-plan → stdd-execute`, with `stdd` and `stdd-lint` callable at any point.

**STDD test-file guard hook** (`hooks/stdd_test_guard.py`) — an opt-in
PreToolUse hook enforcing that a test file with an established RED baseline
can't be rewritten before its task is marked done. Install with
`install.sh --install-hook` (independent of `--stdd-role`). **Session-
snapshot caveat**: Claude Code reads PreToolUse hooks from `settings.json`
once, at session start — running `--install-hook` inside an existing or
`--continue`/`--resume`d session will NOT activate the hook there; verify it
in a brand-new session only.

## Triggering

Auto-invocation of `/rivendell-council` is description-driven — the model
matches the skill description's trigger words against the situation. For a
hard guarantee, add one line to your project's `CLAUDE.md`:

```
High-risk verdicts (irreversible ops, contract/schema changes, money/precision, architecture decisions, root-cause claims, production-affecting conclusions) MUST pass /tlor-orchestration:rivendell-council before adoption.
```

`eagle-sentinel`'s HIGH-RISK recommendation is the convening signal.
