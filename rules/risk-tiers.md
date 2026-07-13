---
version: 1.0.0
description: Classify a state-changing action into a risk tier before acting, and apply that tier's required protocol.
---

# risk-tiers.md — Classify the action, then apply the tier's protocol

Audience: main-conversation model AND subagents. Before any state-changing
action (edit, delete, run, commit, send), classify it into a tier and do that
tier's required steps. **Unsure which tier? Treat it as the higher one.**
This file unifies the risk rules scattered across the dispatch and judgment
rubrics and general commit hygiene.

## Tier table

| Tier | Definition | Example actions | Required protocol |
|---|---|---|---|
| **T1 — irreversible / outward-facing** | Cannot be undone by you, or leaves the machine | force-push; delete files not created this session; `git push` to any remote; publish/send/email; spend money; drop a database or table; edit git history; anything touching a project's `main` | **STOP and ask the user first** (batch with other questions), unless the user explicitly requested this exact action this session |
| **T2 — hard to undo** | Recoverable but costly: needs a backup, a rebuild, or careful reversal | overwrite/rewrite an existing file wholesale; batch edits across many files; schema/migration changes in a dev database; edits to rules files, CLAUDE.md, AGENTS.md, memory files; deleting scratch data another step still needs; changing CI or container config | **Backup first** (`cp X X.bak-YYYYMMDD`), then act, then fresh-context verification; for judgment-heavy T2, second opinion from an independent high-capability agent |
| **T3 — reversible** | Undo is one command or one edit away | edits to files already under active work; creating NEW files; running tests/builds; read-only commands; scratchpad writes; starting a local service | Just do it, then verify. No ceremony |

## Classification rules (apply in order)

1. Does the effect leave this machine or this session's control (push, send,
   publish, spend)? → **T1**.
2. Would recovery require information you might not have afterwards (no
   backup, no version control)? → **T1** for deletion of pre-existing work,
   **T2** for overwrites you can back up first.
3. Does it modify shared, long-lived state (rules files, memory, DB schema,
   configs) rather than task-local files? → at least **T2**.
4. Otherwise → **T3**.

Two modifiers:
- **Scale escalates**: a T3 edit applied to 20 files at once is T2 (batch
  errors are costly to unwind). One-file typo fix stays T3.
- **User instruction de-escalates one step at most**: "delete the old backups"
  makes that deletion T2 (confirm target matches description, then act), not
  T3 — and nothing the user says makes force-push-to-main routine.

## Per-tier examples of the protocol done RIGHT

- **T1 done right**: task says "clean up old scripts"; two script dirs exist,
  one referenced by a cron-looking file. Deletion of pre-existing files =
  T1 → ask which dir, one batched question.
- **T2 done right**: rewriting a rules file → `cp rules-file.md
  rules-file.md.bak-YYYYMMDD`, edit, then a fresh agent re-reads the file
  against the change's acceptance criteria. Backup deleted (or gitignored)
  once the user confirms the rewrite.
- **T3 done right**: adding a new test file and running the test suite —
  no backup, no question; quote the test output as verification.

## Out-of-bounds recovery (a subagent edited outside its dispatch scope)

Back up the bad state FIRST (`cp X X.bak-YYYYMMDD`). Inside a version-
controlled project, use `git diff` to identify and revert ONLY the
out-of-scope hunks — never whole-file `git checkout`, which destroys
in-scope uncommitted work. Outside version control, restore from the
pre-edit backup the T2 protocol required; if none exists, treat as T1 data
loss and tell the user before touching anything else.

## Anti-patterns (these are how risk discipline actually fails)

- **Tier-shopping**: noticing an action is T2 and re-describing it to
  yourself as T3 ("it's just a small rewrite"). The tier comes from the
  classification rules, not from how confident you feel.
- **Retroactive backups**: making the backup after the edit. Worthless.
- **Asking-as-insurance**: dumping T3 decisions on the user to avoid
  responsibility. That erodes trust in your autonomy — the rubric exists so
  you DON'T ask about T3.
- **Silent T1**: performing a T1 action and mentioning it afterwards in the
  summary. If you find yourself writing "I also pushed…", the process
  already failed; report it prominently, not buried.

## Lessons

(append per maintenance.md format)
