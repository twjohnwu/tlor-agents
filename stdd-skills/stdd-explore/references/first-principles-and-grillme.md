# Reference: six-phase first-principles method + grill-me-style confirm-then-ask

Distilled reference for `stdd-explore`'s Step 3 (six-phase questioning) and
Step 4 (batched, confirm-then-ask questioning). See `SKILL.md` for how these
are applied inline, without dispatching a sub-agent.

## Six-phase first-principles method

Distilled from [danyuchn/first-principles-skill](https://github.com/danyuchn/first-principles-skill)
(MIT, verified 2026-07-18). Walk through every REQ-level assumption in the
idea using these six phases, in order, making the reasoning visible in your
replies rather than performing it silently:

| Phase | Name | What to ask |
|---|---|---|
| 0 | Delete First | Should this requirement exist at all, before optimizing it? (This phase alone covers the "delete before optimize" instinct behind Musk's five-step algorithm — there is no separate step for that.) |
| 1 | Problem essence | What problem is this requirement actually solving? |
| 2 | Challenge assumptions | What assumptions in the user's statement are implicit and untested? |
| 3 | Ground truths | What facts can't be simplified any further? |
| 4 | Upward reasoning | Derive a solution only from the Phase 3 ground truths — don't skip steps. |
| 5 | Verification | Trace the proposed solution back to Phase 3's ground truths and confirm it still holds. |

Do this per assumption, not once for the whole idea — a feature idea usually
carries more than one assumption worth challenging (data shape, scope
boundary, "who consumes this").

## Grill-me-style confirm-then-ask questioning

Distilled from the questioning technique in [mattpocock/skills](https://github.com/mattpocock/skills)'s
`grill-me` skill (license not stated at the source; only the technique
itself is distilled here, no source code is reused; verified 2026-07-18).

The technique: before each batch of questions, restate your current
understanding of the requirement in one sentence and ask the user to confirm
or correct it — THEN ask the next batch. This does not add extra question
rounds on top of the existing discipline; it replaces a bare question dump
with one that opens with a one-sentence recap.

**Discipline this technique runs inside (does not override):**
- Batches of at most 4 questions.
- Soft total target of at most 8 questions per explore session (per
  subsystem, if `stdd-explore` Step 2 detected a multi-subsystem split).
- The user may request +4 more at any point, repeatable, no upper limit —
  but only the user can trigger an extension; the skill never grants itself
  extra budget.

**Worked micro-example:**

> "So the CSV output should represent exactly the same rows/columns as the
> XLSX export, just serialized differently — is that right, or do you also
> want a reduced column set for CSV?"
> [user confirms or corrects]
> "Got it. Next: (1) UTF-8 or does a downstream tool need Big5? (2) comma or
> semicolon delimiter? (3) should the CSV button sit next to the XLSX button
> or in a format dropdown?"

See `templates/handoff-summary.md` for how these phases and questions show up
in the final handoff artifact.
