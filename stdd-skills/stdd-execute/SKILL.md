---
name: stdd-execute
description: 'STDD execute phase — narrative title "Forge 鑄造" (RED/GREEN forged into a finished tool; echoes gondor-builder/eagle-sentinel). Runs the per-task RED → GREEN → REFACTOR TDD loop against an approved STDD tasks.md, using a two-dispatch model (builder-RED, builder-GREEN+REFACTOR) with an independent verifier and a test-file fingerprint passed through the dispatch prompt. Triggers: "stdd-execute", "run the TDD loop task by task", "run RED GREEN REFACTOR", or any request to implement STDD tasks one at a time. Requires an approved spec.md and an existing tasks.md; refuses otherwise.'
---

# stdd-execute — Forge 鑄造

Fourth phase of the STDD pipeline. Implements each `tasks.md` task with a
strict RED → GREEN → REFACTOR loop and a task-boundary spec re-check.
Canonical spec: `STDD/specs/stdd-execute.md` (REQ-04); cross-cutting
mechanisms (frontmatter status, dual-fingerprint rule, `[wip]`/`[x]`
semantics, Lint-STOP, design-ux consistency check) are canonical in
`STDD/spec.md` — referenced here, not restated.

## 0. Precondition

`stdd-plan`'s own coverage/approval gate (S-08) already blocks tasks.md from
existing without an approved spec — do not re-invent an extra triage
checkpoint here. Do read `tasks.md` for any `[wip]` task before starting new
work (see step 3, interrupt recovery) — a `[wip]` task means the previous
`stdd-execute` run was interrupted, and recovery is this skill's job, not
`/stdd`'s (`/stdd` only reports "task X appears interrupted", it never touches the
file).

Only one `stdd-execute` session may run against a given change directory at
a time. STDD provides no file lock for this — it is a documented limit, not
a mechanism; do not treat the absence of a lock error as permission to run
two sessions concurrently.

## 1. Picking a task

Take the next `[ ]` task from `tasks.md` in order (or the `[wip]` task if
recovering an interruption — see step 3). Route it:

- `S-XX` scenario task → full two-dispatch RED/GREEN/REFACTOR loop (steps
  2–5 below).
- `[INFRA]` task, or an obviously small single-file change → the fast path
  (step 6).
- `[MANUAL]` entries are never executed here — they live in the "Manual
  verification checklist" and are confirmed one by one at the completion gate (step 5).

## 2. Dispatch A — builder-RED (S-10)

Dispatch a builder (role `gondor-builder` if tlor-agents/pinned roles are
installed, otherwise a generic subagent with `model: sonnet` stated
explicitly) with these exact instructions:

1. **First**, mark this task `[wip]` in `tasks.md` — this is the *only*
   place `[wip]` gets written, so an interruption after this point is
   detectable later.
2. Read the task's `S-XX` scenario GIVEN/WHEN/THEN from `spec.md`.
3. Write a test function named `test_sXX_<scenario_snake>`.
4. Reference `REQ-XX / S-XX` in the test's docstring.
5. Run the task's verification command and confirm the test **fails for
   the correct reason** (a real assertion failure against the intended
   behavior — not an import error or syntax error).
6. Quote the actual RED output, then **end the dispatch**. **Do not write
   any implementation code** in this dispatch.

After Dispatch A reports back, the **main session** (not the builder) uses
a read-only command (`shasum -a 256 <test file>`) to compute the test
file's content fingerprint itself, and carries that fingerprint plus a
summary of the RED output into Dispatch B's prompt. The fingerprint travels
through the prompt, not through any file the builder can edit — so the
builder cannot tamper with the baseline it's being checked against.

Verification: the test, run directly, exits non-zero with the expected
failure message; Dispatch A's report contains no implementation code.

## 3. Dispatch B — builder-GREEN+REFACTOR (S-11, S-12)

Dispatch a builder (same role selection rule as Dispatch A) carrying the
fingerprint + RED summary from step 2, with these instructions:

**GREEN:**
1. Write the minimum code needed to make the test pass.
2. **Do not modify the test file** — its content must stay identical to the
   fingerprint captured after RED.
3. Run the verification command and confirm the test **passes**.
4. Run the full previously-passing scenario suite and confirm no
   regressions.

**REFACTOR** (same dispatch, not a separate one):
5. Check for SOLID violations (single responsibility, open/closed, Liskov
   substitution, interface segregation, dependency inversion).
6. Check for DRY violations (duplicated logic, copy-paste patterns).
7. Check for code smells (overly long methods, deep nesting, magic
   numbers).
8. Refactor **only** where a violation was actually found.
9. **Do not modify the test file** (same restriction as GREEN).
10. Re-run the full test suite after each refactor change and confirm it
    still passes.

### Interrupt recovery (S-11)

Any interruption during Dispatch A/B recovers via `[wip]` detection
(consumed by this skill, not `/stdd` — see `STDD/specs/stdd-status.md`
S-19):

- **Recovering into or after GREEN**: re-run the task's verification
  command. Even on recovery, the task must still pass the full step-5
  task-boundary check (regression scan + plan-drift check + manual gate,
  same as the normal path) before it may be marked `[x]` — recovery never
  skips the ordinary completion gate.
- **Recovering into RED, or any error state**: reset the task to `[ ]` and
  redo it. Dispatch A rewrites the same-named test file **by overwriting
  it** (this is the one legitimate exception to the fingerprint firewall in
  step 4).
- **Leftover partial implementation, git-tracked project**: use `git diff`
  to identify and **revert only the hunks introduced by this task** — never
  a whole-file `git checkout`, which would destroy uncommitted work from
  earlier tasks in the same file. If attribution of a hunk to this task
  can't be determined, **STOP** and report to the user for a decision.
- **Non-git project**: **STOP** and report to the user for manual
  disposition — do not attempt automatic recovery.

## 4. Dispatch integration & fingerprint firewall (S-14)

- Every scenario task uses exactly two dispatches (Dispatch A, Dispatch B
  above); role selection: `gondor-builder` for both if tlor-agents (or an
  equivalent pinned-role package) is installed, otherwise a generic
  subagent with `model: sonnet` stated explicitly.
- **Independent verifier**, dispatched after Dispatch B (role
  `eagle-sentinel` with `model: sonnet` — the routine read-back override —
  if tlor-agents is installed, otherwise a generic subagent with `model:
  sonnet` stated explicitly). The verifier does:
  - Accepts Dispatch A's quoted RED output as the RED evidence (RED
    evidence = Dispatch A's quote + the main session's checkpoint at that
    time). It is **not** required to reproduce RED.
  - Independently recomputes the test file's current fingerprint (from the
    fingerprint passed through the dispatch prompt in step 2, not from any
    file) and compares it to confirm the test file has not been touched
    since the RED checkpoint. Mismatch → treat as a violation, send back
    for redo. (The fingerprint is a suggested mechanism, not the only valid
    implementation — the actual requirement is "confirm the test file
    wasn't tampered with".)
  - Actually re-runs the verification command and confirms GREEN.
  - Passes the task's spec GIVEN/WHEN/THEN into its own acceptance
    criteria (carried in the dispatch prompt for every dispatch, per
    template convention — not restated here).
- **Builder vs. verifier disagreement**: if they fail to converge after
  **2 rounds**, escalate to the user for a decision — do not grind past
  that cap.
- **Test-file fingerprint firewall**: once Dispatch A establishes the RED
  fingerprint baseline, that test file must not be written to again before
  the task is marked `[x]` — the only legitimate exception is the S-17
  plan-drift-triggered rewrite (Dispatch A overwrites the same-named file
  during recovery, step 3). Any other write is a violation; a mechanical
  layer does not need to distinguish "authorized dispatch" from
  "unauthorized subagent" here — it can block all writes uniformly. This
  firewall is an **optional** PreToolUse hook, **not installed by
  default**; if the hook is installed, document its install/removal steps
  and remove the hook's registration from `settings.json` **before**
  removing the plugin, to avoid an orphaned hook breaking tool calls. When
  the hook is absent (or misses an attempt), `/stdd-lint`'s post-hoc
  fingerprint comparison (`STDD/specs/stdd-lint.md` S-30) is the fallback
  detection — not a preventive one.
  - **Honest disclosure**: `status`/`approved_fingerprint`/
    `design_ux_fingerprint` frontmatter fields have **zero** mechanical
    protection under any circumstance — only user approval in conversation
    plus `stdd-lint`'s post-hoc comparison guard them (see
    `STDD/specs/stdd-spec.md` S-05, `STDD/spec.md` REQ-09). Do not imply
    this skill closes that gap; it doesn't, by design.
- The `[INFRA]` fast path (step 6) still always runs the verifier — it only
  skips the multi-round RED/GREEN dispatch split, not verification.

## 5. Task-boundary spec re-check (S-13)

Once a task's RED → GREEN → REFACTOR is done:

1. Run the verification commands for every scenario covered so far. Any
   regression → **STOP** (treat as a wrong-direction signal per
   judgment.md §4 — do not patch around it).
2. Check whether this task's implementation has drifted from
   `design-be.md` / `design-fe.md` / `api.yml` (plan-drift check). Drift
   found → trigger the plan-change protocol (step 7 / S-17) before
   proceeding further.
3. Call `/stdd-lint` to re-compare `S-XX` coverage between `spec.md` and
   `tasks.md`, and to re-verify both fingerprints: `spec.md`'s body against
   `approved_fingerprint`, and (if `design-ux.md` exists) its body against
   `spec.md`'s `design_ux_fingerprint`. This makes sure execution itself
   hasn't drifted spec/design-ux out from under their recorded
   fingerprints. Apply the design-ux consistency check exactly as defined
   in `STDD/spec.md`'s design-ux consistency check section (single source of
   truth, (a)/(b) branches) — never skip branch (b) just because
   `design-ux.md` happens not to exist.
4. Mark the task `[x]` in `tasks.md`.
5. Report: N/M scenarios green, task K/T complete.
6. **Completion gate**: when all K/T tasks are done (execute is wrapping
   up), confirm every entry in the "Manual verification checklist" (from S-08) one by one
   with the user. Any unconfirmed entry → the completion report MUST say
   "manual verification incomplete: N items" and MUST NOT claim the change is complete.
7. **0/0 boundary**: if every scenario in the change is manual (no TDD
   tasks at all, so K/T doesn't apply), completion = full confirmation of
   the manual verification checklist. The completion report must explicitly
   say "0 TDD tasks" — the K/T-not-applicable case is not an excuse to skip
   this gate.

If `/stdd-lint` is not installed at any of these checkpoints, **STOP** and
report "`/stdd-lint` not installed - mechanical check incomplete" (single-source Lint-STOP
rule, `STDD/spec.md`) — never silently skip the mechanical check.

## 6. Plan-drift protocol (S-17)

When execution reveals that a design file (`design-be.md` / `design-fe.md`
/ `api.yml`) is wrong or incomplete for what the task actually needs:

1. First read `STDD/spec.md`'s "Rejected options" section for this change, to
   avoid re-proposing an option already rejected during `stdd-explore`.
2. **STOP** — do not continue writing implementation code before the
   design file is updated.
3. Update the relevant design file(s) to reflect the corrected design.
4. If `api.yml` changed, re-run the S-16 lint/validate step from
   `stdd-plan`.
5. Only after the update is complete, **resume** the original task.
6. Record the drift and the reason for the change in the task report.
7. **Same-task retry cap** (mirrors the S-14 2-round cap): if this
   protocol triggers a **3rd time** on the same task, **STOP** — do not
   attempt another in-place correction. Instead return to `stdd-plan` to
   re-cut `tasks.md`, and let the user decide how to proceed.

## 7. `[INFRA]` / small-task fast path (S-18)

For a task marked `[INFRA]`, or an obviously small single-file change:

- Mark the task `[wip]` at start and `[x]` on completion, exactly like the
  full path — this keeps S-19's interrupt detection working for `[INFRA]`
  tasks too.
- Run **one** builder dispatch (implementation) and **one** verify dispatch
  — skip the multi-round RED → GREEN → REFACTOR structure, but still
  report execution results and the actual verification command output.
- `tasks.md` must carry a mandatory one-line reason for why this task
  qualifies for the fast path (the mechanical check for a missing reason
  line is `/stdd-lint` S-40, not this skill).
- Never mislabel work that should be a scenario task (`S-XX`) as `[INFRA]`
  just to dodge the full loop.

## Notes / honest limits

- This skill assumes `/stdd-lint` is installed for every mechanical
  checkpoint above; if it is not, the correct behavior is to STOP loudly,
  not to proceed without the check.
- The test-file fingerprint firewall's mechanical hook is optional and off
  by default — without it, protection is detection-after-the-fact via
  `/stdd-lint`, not prevention. Say this plainly in any report, don't imply
  stronger guarantees than exist.
- Status/frontmatter approval fields (`status`, `approved_fingerprint`,
  `design_ux_fingerprint`) are never protected by a mechanical hook under
  any configuration — this is a deliberate framework decision (REQ-09), not
  a gap this skill can close.
