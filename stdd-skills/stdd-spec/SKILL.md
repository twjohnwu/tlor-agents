---
name: stdd-spec
description: 'STDD spec phase — narrative title "Oath 遠征誓約" (swearing an acceptable oath). Writes a GWT-format spec.md with stable REQ/S IDs, test-mapping and verification-command fields per scenario, runs a mechanical /stdd-lint self-review plus an adversarial-panel approval gate, and is the hard gate that blocks stdd-plan/stdd-execute until the spec (and design-ux.md, if any) are approved and their content fingerprints match. Triggers: "/stdd-spec", writing or approving a spec for an STDD change.'
---

# stdd-spec — Oath 遠征誓約

Opt-in skill (installed from `stdd-skills/`, not auto-loaded from the
plugin's `skills/` directory). Precondition: if the change has a UI surface,
`stdd-uiux`'s `design-ux.md` should exist before this skill finalizes the
spec. Worked examples: `templates/spec.md`. Distilled reference: `references/gwt-and-rfc2119.md`.

## Step 0 — Entry triage (only when this change has no `STDD/<name>/` dir yet)

If this change is entering the pipeline for the first time (no existing
`STDD/<name>/` directory — not a follow-up action on an existing change),
run the same four-point check `stdd-explore` runs before its own entry
(don't duplicate the four points here — see `stdd-explore`'s Step 0 for the
exact wording, or ask the user's earlier explore output if it already ran
this check). If any point matches, refuse to start the STDD pipeline: reply
that this change doesn't need the full STDD workflow and suggest handling it
directly via ordinary conversation/existing workflow — never silently skip
this check and generate `spec.md` anyway. If none match, continue to Step 1.

## Step 1 — Cross-check existing project spec/wiki content (before writing spec.md)

If the target project already has prior STDD change directories (or a
`wiki/`), before drafting this change's `spec.md`:

- Dispatch a broad-search subagent (e.g. this framework's `ranger-pathfinder`
  role, if available) to scan existing changes' `spec.md` files and `wiki/`
  (prioritize the `standard/` and `cases/` buckets) for conflicts with this
  change's business logic. Only do this when there is actual existing data
  to check against — skip if there's nothing to scan yet.
- If a conflict is found → report it to the user and let them decide; you
  SHALL NOT pick a side yourself.
- Any new reference material discovered during this exploration/spec work
  gets written into `wiki/` as Obsidian-readable markdown, using the
  project's fixed taxonomy (`design_guideline/`, `reference/`, `standard/`,
  `coding_standard/`, `knowhow/`, `cases/`; unsure → `reference/`), the
  frontmatter convention (`source`, `date`, `tags`), and the
  `wiki/README.md` routing-table rule: check whether `wiki/README.md`
  exists (create if not), and register new files into its routing table
  (relative path + one-line purpose) — never re-register an existing entry.

## Step 2 — Derive a requirements checklist (before generating spec.md)

Before drafting `spec.md`, derive a requirements checklist from the inputs
available (this request, plus any upstream handoff summary from
`stdd-explore` and `design-ux.md` if present). Write it into a non-gated
appendix section of `spec.md`, e.g.:

```markdown
## Requirements Checklist

- [ ] Requirement A
- [ ] Requirement B
```

This checklist is re-checked item by item at the end of Step 5, right
before the spec is presented for approval — any unmet item MUST be listed
explicitly there, never silently marked as done.

## Step 3 — Generate `spec.md`

Create `STDD/<change-name>/spec.md`. **Artifact language**: before writing,
check whether this change directory already has an existing artifact with a
`language:` frontmatter field — if so, reuse that value and don't ask again;
if this is the change's first artifact, ask the user once for the language
(soft default `en`, any language code is acceptable), and write the decision
into this file's own `language:` field for later artifacts in the same
change to reuse (single source of truth: `STDD/spec.md`'s cross-cutting
"Artifact language rule" — referenced here, not restated). Regardless of the
chosen language, GIVEN/WHEN/THEN, `REQ-XX`/`S-XX`, commands, and filenames
always stay in English.

Include:

- Frontmatter with these persisted status fields, written exactly (example
  shows the `en` default; substitute the resolved language code):
  ```yaml
  ---
  status: draft
  approved_date: null
  approved_fingerprint: null
  design_ux_fingerprint: null
  language: en
  ---
  ```
  `design_ux_fingerprint` is a required field, never omit it: fill it in
  with the fingerprint computed at approval time if `design-ux.md` exists;
  for a purely backend/CLI change with no `design-ux.md`, write an explicit
  `null` (a `null` value is excluded from the gate check in Step 6).
- `REQ-XX` requirement IDs and `S-XX` scenario IDs.
- Every scenario in GIVEN/WHEN/THEN format.
- Every scenario's expected test-path mapping field.
- Every scenario's `Verification command` field (a precise, runnable test
  command).
- **Conditional**: if the change touches a system boundary or external
  dependency, add a C1 (Context) / C2 (Container) diagram using Mermaid's
  plain `graph`/`flowchart` syntax (banned constructs: single source of
  truth is `stdd-lint`'s `references/checklist.md` — not restated here).
  The diagram lives in its own document section (e.g. `## System context`),
  NOT as an `S-XX` scenario — a diagram is descriptive context, not a
  testable behavior, so giving it a scenario ID would force a fake "manual
  verification" entry into the coverage math. Omit this diagram when
  there's no boundary/external dependency involved. See `templates/spec.md`
  for a worked C1/C2 example.
- If `stdd-explore` handed off a rejected-options list (or wrote it directly
  if `spec.md` already existed at that time), write it verbatim now into a
  `## Rejected options` section. This section is non-gated: it does NOT
  enter the approval gate and is NOT included in the fingerprint calculation
  (Step 6).

## Step 4 — Self-review before requesting approval

Before asking the user to approve:

- For every `REQ`, apply a first-principles challenge inline (no sub-agent
  dispatch — same phases 0/2 style as `stdd-explore`): is this requirement
  really necessary, is there a simpler alternative?
- Call `/stdd-lint` to run its mechanical scan (placeholder text, scenario
  ID continuity, GWT completeness). If `/stdd-lint` is not installed, STOP
  and report "`/stdd-lint` is not installed, cannot complete the mechanical
  check" — never silently skip this check.
- Report `/stdd-lint`'s findings to the user BEFORE requesting approval.

## Step 5 — Adversarial-panel review (once per gate, not per REQ)

Run exactly ONE adversarial review pass over the whole spec, after Step 4's
self-review passes and before the approval gate — never re-litigate this
per-REQ:

- **Scale rule**: if the spec has only 1 `REQ` and involves no
  contract/schema change, you MAY scale down to a single strong-model
  challenger (still record the outcome in `## Adjudications`, see below).
  If the spec has 2+ `REQ`s, or touches a contract/schema change or an
  irreversible operation, run the full panel.
- **Dispatch rule**: if a pinned-role adversarial-review flow is available
  in this environment (this framework's `rivendell-council` flow, dispatching
  its three lenses e.g. `elf-archer`/`orc-saboteur`/`hobbit-gardener` in
  parallel), use it to review the whole spec. If not available, fall back to
  a single strong-model challenger and explicitly note in the report "not an
  independent multi-lens review" — never fake a majority vote with 3
  same-source weak refuters. This reuses `rivendell-council`'s core logic on
  purpose (a separate `/stdd-challenge` skill is intentionally NOT built) —
  the only differences are the scale-down rule above and the recording
  format below.
- Record every REQ's verdict into a NEW `## Adjudications` section inside
  THIS change's `spec.md` (distinct from `STDD/adjudications.md`, which is
  the STDD framework's own historical review record — do not confuse the
  two). Format:
  ```markdown
  ## Adjudications

  - REQ-01: SURVIVED — no objection
  - REQ-02: REFUTED → revised to ...
  ```
- If a REFUTED verdict's fix changes the spec's content, rerun Step 4's
  self-review (`/stdd-lint` scan) before proceeding to the approval gate.
- **Division of labor with the reflow protocol**: `stdd-uiux`'s reflow
  protocol normally only needs a lightweight user re-approval for a UX
  delta and does NOT re-trigger this adversarial panel, UNLESS the delta
  involves a REQ-level change — this is the single source of truth for that
  rule; `stdd-uiux` only references it.
- **Requirements checklist close-out**: go through Step 2's checklist item
  by item. Any item still unmet MUST be listed explicitly in the report
  handed to the user next — never silently treated as satisfied.
- **Disposition of unmet items**: any unmet item is handed back to the
  orchestrating main session (Maia) to re-design and dispatch corrective
  work orders. Only when the main session cannot adjudicate (a
  requirement-level ambiguity, or mutually exclusive trade-offs) does it ask
  the user.

## Step 6 — Hard gate: spec must be approved before `stdd-plan` runs

While `spec.md`'s frontmatter `status` is not `approved`, you SHALL NOT call
`stdd-plan` or allow any code to be written:

- Downstream skills (`stdd-plan`, `stdd-execute`) SHALL refuse to run and
  report why whenever the prior stage isn't approved, or was approved but
  its content changed afterward (see fingerprint check below). Exactly where
  the gate check code lives isn't prescribed — only that this refusal
  behavior is observable.
- **Dual-file fingerprint**: when `design-ux.md` exists, the approval gate
  covers BOTH files — `spec.md`'s own `approved_fingerprint` AND
  `design_ux_fingerprint` (the fingerprint of `design-ux.md`'s content,
  stored inside `spec.md`). Either file's content changing after approval →
  gate rejects. A change with no `design-ux.md` checks only the single
  `spec.md` fingerprint.
- **design-ux consistency check**: also verify `design_ux_fingerprint` in
  `spec.md`'s frontmatter agrees with whether `design-ux.md` actually
  exists: (a) fingerprint non-null but `design-ux.md` missing → FAIL
  "design-ux.md missing"; (b) fingerprint null but `design-ux.md` DOES exist
  → FAIL "design-ux.md not covered by approval", requiring the backfill
  path from `stdd-uiux`'s reflow protocol to add the fingerprint and
  re-approve. Never silently skip either check.
- **Fingerprint scope and algorithm**: the fingerprint covers each file's
  content ONLY (everything after the YAML frontmatter block), algorithm
  fixed as `shasum -a 256` (computed directly over the content bytes) —
  frontmatter fields themselves (`status`/`approved_date`/the fingerprint
  fields being written) never affect the fingerprint's own input, avoiding
  a self-referential loop.
- **Content-extraction rule**: content = everything after the SECOND `---`
  line (the end of the frontmatter block) in the file, including trailing
  newlines, with no normalization. If there's no frontmatter, content = the
  whole file.
- Present the spec (and `design-ux.md` if present) for review and wait for
  explicit approval. On approval: set `status: approved`, fill in
  `approved_date`, and compute + write the content fingerprint(s) as defined
  above into `approved_fingerprint` (and `design_ux_fingerprint` if
  applicable).
- Whenever a downstream gate checks `status`, it SHALL also recompute each
  file's content fingerprint using the same definition and compare against
  the recorded value; any mismatch is treated as `draft` — reject and report
  "spec (or design-ux) changed after approval, needs re-approval."
- **Honest disclosure**: this is a prose rule, not a mechanical guarantee —
  nothing prevents a model from writing `approved` status or a fingerprint
  itself. The `status`/`approved_fingerprint`/`design_ux_fingerprint` fields
  SHALL NOT depend on any mechanical hook protection (an earlier design that
  had a hook block writes to these fields was reversed: an approved write is
  the normal "user approved → main session authorized → a subagent or the
  main session writes it" path, and a tool-call-level hook cannot
  distinguish that from tampering). The only approval signal is the user's
  explicit confirmation in conversation; the only after-the-fact backstop is
  `/stdd-lint` recomputing and comparing content fingerprints. This is a
  detection-only, not prevention, residual risk, and it's accepted knowingly.

## `templates/` and `references/`

This skill directory ships:

- `templates/spec.md` — a complete English worked example of a change-level
  `spec.md`: full frontmatter (`status`/`approved_date`/`approved_fingerprint`/
  `design_ux_fingerprint`/`language`), at least one full GWT scenario with
  `Test mapping`/`Verification command`, a `## Rejected options` section
  example, a `## Adjudications` section example, and a conditional C1/C2
  Mermaid `graph` example (banned constructs live only in `stdd-lint`'s
  `references/checklist.md`, not restated here — R7-1).
- `references/gwt-and-rfc2119.md` — a distilled reference on GWT quality
  rules, the frontmatter contract, and common mistakes.

## Notes for a fresh session

- Run the adversarial panel exactly once per gate (Step 5), not once per
  REQ, and not again for routine small edits.
- Never let `stdd-plan`/`stdd-execute` proceed on an unapproved or
  fingerprint-mismatched spec — that refusal is this skill's whole reason to
  exist as a gate.
- `## Adjudications` (per-change, inside this `spec.md`) and
  `STDD/adjudications.md` (the STDD framework's own history) are different
  files — don't conflate them in reports.
- The requirements checklist (Step 2) is a non-gated appendix, distinct from
  `## Rejected options` and `## Adjudications` — all three live in the same
  `spec.md` but serve different purposes.

## Closing — decision capture (advisory)

Before closing this phase, check whether it produced a decision that
passes the durability test (any of: changes a contract, schema,
architecture, or convention with future consequences; encodes a
non-obvious transferable lesson; guards against a plausible future
re-litigation of the same argument). If yes, ask the user with
AskUserQuestion — explicit options, never an open-ended question:
(a) archive to the project's decision log, (b) archive as a general
(cross-project) decision, (c) don't archive. If they pick an archive
option, invoke `/westmarch-scribe` with this phase's filled MADR /
decision material. This is a suggestion gate — never invoke the scribe
without the user choosing it.
