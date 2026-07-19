---
name: stdd-plan
description: 'Map 行軍圖 — generate condition-based design artifacts (design-be.md / design-fe.md / api.yml) and a scenario-covered tasks.md from an approved STDD spec.md. Triggers: "stdd-plan", "generate design and task list", "produce a plan from spec", or any request to turn an approved GWT spec into a design + task list. Requires spec.md status: approved; refuses to run otherwise.'
---

# stdd-plan — Map（行軍圖）

Third phase of the STDD pipeline (`stdd-explore → stdd-uiux (conditional) →
stdd-spec → stdd-plan → stdd-execute`). Turns an approved `spec.md` into
condition-based design artifacts and a scenario-covered `tasks.md`. Canonical
spec: `STDD/specs/stdd-plan.md` (REQ-03); cross-cutting mechanisms (frontmatter
status fields, dual-fingerprint rule, wiki/ taxonomy, Lint-STOP rule) are
canonical in `STDD/spec.md` — this skill references them, it does not restate
them. Worked examples: `templates/design-be.md`, `templates/tasks.md`.
Distilled references: `references/openapi-skeleton.md`,
`references/23-design-patterns.md`.

## 0. Gate check (precondition, spec S-06/S-08)

Before doing anything else, read `STDD/<name>/spec.md` frontmatter (and
`STDD/<name>/design-ux.md`'s existence, if any):

- If `spec.md` `status` is not `approved` → **refuse to run**, report why,
  and stop. Do not produce any design artifact or tasks.md.
- If `status: approved`, recompute the body fingerprint with `shasum -a 256`
  over the content after the second `---` (the frontmatter-stripped body; no
  frontmatter → whole file) and compare against `approved_fingerprint`. If a
  `design-ux.md` exists, also recompute its body fingerprint and compare
  against `spec.md`'s `design_ux_fingerprint`. Any mismatch → treat as
  `draft`, refuse, and report "spec (or design-ux) changed after approval,
  needs re-approval."
- Design-ux consistency check (single source of truth in `STDD/spec.md`
  "design-ux consistency check"): `design_ux_fingerprint` non-null but
  `design-ux.md` missing → FAIL "design-ux.md missing"; fingerprint null but
  `design-ux.md` exists → FAIL "design-ux.md not covered by approval" and
  point the user at the `stdd-uiux` back-fill flow. Never skip this check
  because a file is absent.

This same gate re-check happens again in step 6 before the tasks.md coverage
gate (S-08) — re-read `spec.md` frontmatter at that point too, not just once
at skill entry.

## 1. Aspect detection

Read `spec.md` in full and detect which aspects apply: backend, frontend,
API contract. **If detection is ambiguous, ask the user — never guess.**
Only produce the design artifacts for aspects that actually apply; mark
inapplicable sections `N/A` rather than omitting them silently.

## 2. Requirements checklist (S-51)

Before producing any design artifact (step 3), derive a requirements
checklist from the approved `spec.md` (and `design-ux.md` if present) and
write it into a non-gated appendix section — either its own subsection in
`tasks.md` or in `design-be.md`'s appendix, e.g.:

```markdown
## Requirements Checklist

- [ ] Requirement A
- [ ] Requirement B
```

This checklist is re-checked item by item at the end of step 6's coverage
gate, right before the approval summary is presented. Any unmet item MUST be
listed explicitly there — never silently treated as satisfied.

**Artifact language**: before generating any design artifact (step 4
onward), check whether this change directory already has an existing
artifact with a `language:` frontmatter field (e.g. `spec.md`, written by
`stdd-spec`) — if so, reuse that value and don't ask again; if somehow no
artifact in this change has defined one yet, ask the user once for the
language (soft default `en`, any language code is acceptable). Write the
resolved value into the `language:` frontmatter field of the design
artifacts this skill produces (`design-be.md`, `design-fe.md`, `tasks.md`)
for later artifacts in the same change to reuse (single source of truth:
`STDD/spec.md`'s cross-cutting "Artifact language rule" — referenced here,
not restated). Regardless of the chosen language, GIVEN/WHEN/THEN,
`REQ-XX`/`S-XX`, commands, and filenames always stay in English.

## 3. Existing-project design-pattern suggestion (S-52)

During the file survey that informs the design artifacts below, on an
**existing** project (not a brand-new one): if the survey turns up similar
functionality already implemented, before finalizing `design-be.md` /
`design-fe.md`:

- Read `references/23-design-patterns.md` (this skill's bundled template, or
  the project's own canonical `wiki/coding_standard/` copy if a prior run
  already landed one — see step 8).
- Produce a suggestion list: for each candidate pattern, one line naming the
  pattern, one line of rationale, and the specific point in the existing
  implementation where it would apply.
- Present this list to the **user** and let them decide whether to adopt any
  of it — you SHALL NOT apply a suggested pattern without the user's
  explicit go-ahead.
- If the user skips the suggestions, produce the design as originally
  planned — do not force any pattern in.
- If no similar existing implementation is found, or the target is a
  brand-new project, skip this flow entirely and fall back to step 8's
  ordinary "repeated structure or predictable variation point" bar for
  introducing a pattern.

## 4. Design artifacts (S-06)

Conditionally produce, each referencing the relevant `REQ-XX` from spec.md:

- **`STDD/<name>/design-be.md`** — BE plan, table schema (markdown field
  tables), a services relationship diagram, a Mermaid sequence diagram, and
  a conditional **C3 (Component)** diagram when the change splits internals
  within a container. All diagrams use plain Mermaid `graph`/`flowchart`
  syntax (banned constructs: single source of truth is `stdd-lint`'s
  `references/checklist.md` — not restated here). See `templates/design-be.md`
  for a worked example of both diagram types.
- **`STDD/<name>/design-fe.md`** — follows the fused Sean Chou 4-section +
  frontendatscale 9-section template referenced in `STDD/spec.md`'s
  documentation-standards section; small changes may trim sections down.
- **`STDD/<name>/api.yml`** — the **only** machine-verifiable contract file
  (OpenAPI 3.1). API shape lives here and *only* here — `design-be.md`,
  `design-fe.md`, and any diagram may reference it but must never redefine
  the shape (single source of truth). See `references/openapi-skeleton.md`
  for a starting skeleton.

Every design file cites the `REQ-XX` it implements. Verification: `grep -c
"REQ-" STDD/<name>/design-be.md` (or `design-fe.md`, whichever aspect
applies) returns >0; sections marked `N/A` are not failures.

## 5. api.yml lint/validate (S-16)

Once `api.yml` exists:

- If a lint tool is available in the environment (e.g. `redocly`), run it
  (e.g. `redocly lint STDD/<name>/api.yml`) and include the actual output as
  this artifact's own verification hook.
- If no lint tool is available, degrade gracefully to a built-in structural
  check: YAML parses, an `openapi` version field exists, `paths` exists with
  required fields; `components` is optional under OpenAPI 3.1 but if present
  must be structurally valid. State plainly in the plan report "not fully
  linted" when this degraded path is taken.
- If lint (or the degraded check) fails, report it and require a fix
  **before** presenting the plan for approval.
- **Mandatory disclosure in the approval summary**: when the degraded path
  was taken, the approval summary handed to the user in step 7 MUST include
  the line "api.yml: structural check only, not schema-level linted" — it is
  not enough for this to appear only in the plan body; omitting it from the
  approval summary is a spec violation.

## 6. tasks.md generation (S-07)

Produce `STDD/<name>/tasks.md`. Classify every task by scenario nature:

- **Automatable scenarios** → a full TDD task, each including:
  - one or more `S-XX` scenario-ID references
  - explicit TDD steps: RED → Verify RED → GREEN → Verify GREEN → REFACTOR
    (incl. SOLID + DRY check) → Spec re-check
  - the exact test file and function name to write
  - the exact verification command
  - a per-task status mark, one of three states: `[ ]` / `[wip]` / `[x]`
- **`[MANUAL]` scenarios** (interactive scenarios spec.md marks manual, e.g.
  the S-01/S-02/S-04/S-05 class) → mark `[MANUAL]`, no TDD steps; instead
  list them in the "Manual verification checklist" at the end of tasks.md
  (consumed by `stdd-execute`'s completion gate, S-13).
- **Infrastructure tasks with no scenario ID** → mark `[INFRA]` explicitly.
- **Reason line is mandatory**: every `[INFRA]` or `[MANUAL]` task MUST
  carry one line explaining why it is not a full TDD task. A missing reason
  line is a FAIL when `/stdd-lint` runs (S-40).
- **Optional task-dependency visualization**: if the user wants a
  dependency graph, produce a Mermaid `flowchart` (banned constructs: single
  source of truth is `stdd-lint`'s `references/checklist.md` — not restated
  here). See `templates/tasks.md` for a worked example.

Verification: every task in tasks.md carries an `S-XX` (TDD or `[MANUAL]`)
or `[INFRA]` label; TDD tasks use one of the three status marks; every
`[INFRA]`/`[MANUAL]` task has a reason line.

## 7. Coverage gate before approval (S-08)

Before presenting the plan for approval:

- Re-read `spec.md`'s `status` frontmatter (same gate check as step 0).
- Call `/stdd-lint` (see `STDD/specs/stdd-lint.md`) to compare `S-XX`
  coverage between `spec.md` and `tasks.md`, split by manual vs
  automatable:
  - Automatable scenarios must be 100% covered by TDD tasks in tasks.md.
  - Manual scenarios must be 100% covered by entries in the "Manual
    verification checklist".
  - Either path under 100% (and not explicitly deferred by the user under
    D5) → block and report which scenarios are uncovered.
- If `/stdd-lint` is not installed, **STOP** and report "`/stdd-lint` is not
  installed, cannot complete the mechanical check" — do not silently skip
  the coverage check (this is the single-source Lint-STOP rule in
  `STDD/spec.md`; do not restate it elsewhere).
- `[INFRA]` tasks and any `prototype/` content are excluded from the
  coverage denominator.
- **Requirements checklist close-out** (S-51): go through step 2's checklist
  item by item. Any item still unmet MUST be listed explicitly in the
  approval summary below — never silently treated as satisfied.
- **Disposition of unmet items**: any unmet item is handed back to the
  orchestrating main session (Maia) to re-design and dispatch corrective
  work orders. Only when the main session cannot adjudicate (a
  requirement-level ambiguity, or mutually exclusive trade-offs) does it ask
  the user.
- **The approval summary MUST include** (both sourced from `/stdd-lint`
  S-40's output, not re-derived independently):
  - the full `[INFRA]`/`[MANUAL]` tag list with each reason line
  - the D5-deferred scenario ratio as "x/y (z%)" plus a per-item list

  Neither of these may exist only in tasks.md's body while being omitted
  from the approval summary — the summary is what the user's eyes actually
  check before approving.
- Present the plan (design artifacts + tasks.md + the above summary) to the
  user and wait for explicit approval before any code gets written.

## 8. No-placeholder rule (S-09)

Call `/stdd-lint` to reject any task containing: "TBD", "TODO", "add
appropriate error handling", "similar to Task N" with no concrete content,
undefined type references, or empty verification commands. Require the
author to fill in every field before continuing — do not present an
incomplete plan for approval.

## 9. Design principles + patterns checklist (S-43)

Once `design-be.md` / `design-fe.md` exist:

- Attach a SOLID + DRY review checklist and go through it item by item.
- GoF design patterns (23 total) are used only when justified: a pattern is
  warranted only when there is a repeated structure or a predictable point
  of variation. Introducing a pattern without that justification is
  over-design and the review FAILs — patterns are optional, not a quota.
  (Step 3's S-52 flow is the exception: there, suggestions are presented
  even without that bar being met yet, because the user makes the call.)
- This skill's `references/` directory ships a distilled 23-patterns
  template (a name catalogue with a one-line "when to apply" note each; the
  original source is tracked in `STDD/spec.md`'s reference table, not
  reproduced here).
- **First run in a target project**: land that template into
  `wiki/coding_standard/`, following the classification and
  `wiki/README.md` routing-table rules in `STDD/spec.md`'s wiki
  knowledge-base section (canonical — do not restate the taxonomy here):
  - if `wiki/README.md` does not exist, create it
  - register the new file into its routing table (relative path + one-line
    purpose); do not re-register an entry that's already listed
- **After the first run**, the project's own copy under `wiki/coding_standard/`
  is canonical (the team may customize it) — read the project copy, not the
  bundled `references/` template, on subsequent runs (this is also the copy
  step 3's S-52 flow reads once it exists).

Verification: inserting a pattern with no repeated-structure justification
into a design file and running review must FAIL as over-design; on first
run in a target project, `wiki/coding_standard/` gets the template file and
it is registered in `wiki/README.md`'s routing table; subsequent runs read
the project copy.

## `templates/` and `references/`

This skill directory ships:

- `templates/design-be.md` — a complete English worked example: table
  schema, services relationship diagram, a Mermaid **sequence diagram**
  example, and a conditional **C3 (Component)** Mermaid `graph` example
  (banned constructs live only in `stdd-lint`'s `references/checklist.md`,
  not restated here — R7-1).
- `templates/design-fe.md` — a complete English worked example: component
  structure, state/data flow, a reference back to `design-ux.md` decisions,
  and a Mermaid `flowchart` example.
- `templates/tasks.md` — a complete English worked example with `[ ]` /
  `[wip]` / `[x]` / `[INFRA]` / `[MANUAL]` tasks, S-07 reason lines, and an
  optional task-dependency Mermaid `flowchart` example.
- `references/openapi-skeleton.md` — an OpenAPI 3.1 skeleton fragment.
- `references/23-design-patterns.md` — the S-43/S-52 distilled 23-patterns
  catalogue (unchanged from prior versions — see step 9/step 3 above for how
  it's consumed).

## Notes / honest limits

- This skill enforces the plan-stage gates it can check mechanically
  (fingerprint, coverage, placeholders) via `/stdd-lint`; it has no
  mechanical hook protection of its own — the approval-gate honesty
  disclosure lives in `STDD/spec.md` REQ-09 and is not repeated here.
- If aspect detection, api.yml lint availability, or scenario
  manual/automatable classification is genuinely ambiguous, ask the user —
  do not guess a shape that later has to be unwound.
- The requirements checklist (step 2) and the design-pattern suggestion flow
  (step 3) are both non-gated advisory mechanisms — neither blocks
  producing the design artifacts on its own; only the coverage gate (step 7)
  and the no-placeholder rule (step 8) can block approval.
