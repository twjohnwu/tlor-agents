---
name: stdd
description: 'STDD status phase — narrative title "Palantír 真知晶石" (the seeing-stone that overlooks the whole expedition). A read-only status dashboard for an STDD change: reads existing artifacts (spec.md, design-ux.md, tasks.md), reports which stage the change is in, re-verifies the two-file fingerprint on a read-only basis, and suggests the next command. Never invokes any other stdd-* skill and never writes to any file. Triggers: "/stdd", "what stage is this change in", checking STDD progress.'
---

# stdd — Palantír 真知晶石

Opt-in skill (installed from `stdd-skills/`, not auto-loaded from the
plugin's `skills/` directory). Pure read-only status reporter for a single
`STDD/<name>/` change directory. It SHALL NOT write to any file and SHALL
NOT call any other `stdd-*` skill on the user's behalf — it only reports and
recommends; the decision to proceed stays with the user.

## Step 0 — Determine which change directory this is

Confirm which `STDD/<name>/` directory the user is asking about (the current
working directory, or one named explicitly). If no `STDD/` artifact exists at
all under it (no `spec.md`, no `design-ux.md`), report **"not started"** and
suggest calling `/stdd-explore`. Stop here — nothing further to check.

## Step 1 — Read the existing artifacts

If any artifact exists, read (do not merely list) the following, each only if
present:

- `design-ux.md` — **existence only**. Do NOT attempt to read or reason about
  any frontmatter/status field on this file — `design-ux.md` carries no
  status field of its own (the per-skill spec for `stdd-uiux` is explicit
  that its frontmatter has no `status` key); only `spec.md`'s frontmatter is
  ever a status source.
- `spec.md` — full content, especially its frontmatter (`status`,
  `approved_date`, `approved_fingerprint`, `design_ux_fingerprint`).
- `tasks.md` — full content, if present, including any `[wip]`/`[x]`/`[ ]`
  task markers.

`spec.md`'s frontmatter `status` and fingerprint fields are the **single
source of truth** for stage determination — never infer stage from
`design-ux.md` or `tasks.md` content alone.

## Step 2 — uiux-stage detection (read-only, no frontmatter read on design-ux.md)

- If `design-ux.md` exists but `spec.md` does NOT exist yet: report
  **"uiux in progress"** and suggest calling `/stdd-spec` next.
- If `design-ux.md` does NOT exist, but there is a strong signal the change
  has a UI surface (e.g. the change directory name, or an existing
  handoff/explore summary, clearly mentions UI/UX): only **hint** that
  `/stdd-uiux` might be worth considering. This is advisory only — never
  force it, never call it automatically.

## Step 3 — Dual-fingerprint read-only recompute (only when `spec.md` status is `approved`)

Do this ONLY when `spec.md`'s frontmatter `status` is `approved`. This entire
step is read-only — it SHALL NOT write to any file.

1. **v2 migration guard first**: if `design_ux_fingerprint` is entirely
   **absent** from `spec.md`'s frontmatter (the key itself is missing, not
   merely set to `null`), do not attempt any fingerprint comparison. Instead
   report that this `spec.md` looks like a pre-v3 artifact missing the
   two-file-fingerprint field, and that it needs a one-time re-approval
   before gates will accept it (per the STDD integration spec's v2→v3
   migration clause). Skip the rest of this step for this run.
2. Otherwise, using `shasum -a 256`, recompute the body-only fingerprint of
   `spec.md` — the body is everything after the file's **second** `---` line
   (frontmatter terminator); if there is no frontmatter, the body is the
   whole file. Compare against `spec.md`'s `approved_fingerprint`. Mismatch →
   report **"changed after approval: spec.md"**.
3. If `design_ux_fingerprint` is present and non-`null`:
   - If `design-ux.md` does not exist on disk → report **"design-ux.md
     missing"** (a FAIL, not a silent skip).
   - If it exists, recompute its body-only fingerprint the same way and
     compare against `spec.md`'s `design_ux_fingerprint`. Mismatch → report
     **"changed after approval: design-ux.md"**.
4. If `design_ux_fingerprint` is present and `null`, but `design-ux.md`
   **does** exist on disk → report **"design-ux.md not covered by approval"** (this is a
   FAIL, not a legal state — the file exists but was never brought into the
   approval gate; the remediation path is `stdd-uiux`'s backfill flow, not
   something `/stdd` performs itself).
5. `design_ux_fingerprint` present and `null`, and `design-ux.md` does not
   exist → this is the normal, legal "no UI surface" state. No migration, no
   FAIL.

## Step 4 — Report current stage and next command

Report the change's current stage in plain language, one of (Middle-earth
flavor wording optional, but the state itself must be unambiguous):

- `uiux in progress`
- `spec awaiting approval`
- `plan pending`
- `execute in progress N/M complete` (count `[x]` vs total tasks in `tasks.md`)

Then suggest exactly one next command appropriate to that stage (`/stdd-uiux`,
`/stdd-spec`, `/stdd-plan`, or `/stdd-execute`).

## Step 5 — `[wip]` interruption detection

If `tasks.md` contains any task marked `[wip]`, report **"task X appears
interrupted"** and suggest the user run `stdd-execute` to recover. Do NOT attempt to
re-run any verification command yourself, and do NOT rewrite the `[wip]`/`[x]`
marker — the actual recovery procedure (re-running verification, deciding
RED/GREEN handling) belongs entirely to `stdd-execute`.

## Notes for a fresh session

- This skill never calls another `stdd-*` skill and never writes any file —
  every step above is read-only (`shasum -a 256` recomputation included).
- `stdd-lint` performs the same fingerprint/consistency checks as a
  mechanical, callable-anywhere checker; this skill's checks exist so a
  human gets an immediate human-readable status report without having to
  invoke `stdd-lint` separately — the two are not mutually exclusive, and
  this skill does not require `stdd-lint` to be installed to function.
- If you cannot tell whether a directory is a git project or not, that does
  not matter here — this skill's checks are all plain file reads, no git
  status scanning.
