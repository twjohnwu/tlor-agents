---
name: stdd-explore
description: 'STDD explore phase — narrative title "Lore 智者探詢" (seeking counsel from the wise, gathering intelligence). A thinking-partner mode that clarifies a vague feature idea BEFORE any spec gets written: challenges assumptions with a six-phase first-principles method, asks batched confirm-then-ask questions, proposes 2-3 tradeoff options, and hands off to stdd-uiux or stdd-spec. Writes no code or files except a rejected-options note. Triggers: "/stdd-explore", starting a new STDD change from a rough idea.'
---

# stdd-explore — Lore 智者探詢

Opt-in skill (installed from `stdd-skills/`, not auto-loaded from the
plugin's `skills/` directory). This is a conversational, thinking-partner
skill: it produces at most one small note (a rejected-options list), never
code, never a spec file itself.

## Step 0 — Entry triage (only when this change has no `STDD/<name>/` dir yet)

Before doing anything else, check whether the target project already has an
`STDD/<name>/` directory for this change. If it does NOT (this is the first
time this change enters the pipeline), run this exact four-point check
against the user's request. If ANY point matches, you SHALL NOT enter the
explore flow below — instead reply "this change doesn't need the full STDD
workflow, doing it directly" and STOP:

1. The change is a pure typo fix (no logic/behavior change).
2. The change is confined to one line (or a few contiguous lines of the same
   statement) in a single file, adds no new requirement/scenario, and touches
   no contract.
3. This is a pure Q&A request (the user wants an explanation/lookup of
   existing code or docs, not a change).
4. The user has already given explicit, step-by-step implementation
   instructions in the conversation — no new design decision is needed from
   explore/spec.

If none of the four match, treat this as needing the full STDD flow and
continue to Step 1. (If a `STDD/<name>/` dir already exists for this change,
skip this triage — it only applies to a change's first entry.)

## Step 1 — Understand the idea

Read the user's feature description. If a code-search tool (e.g. a
repository-search subagent) or a web-search tool is available, use it to
gather background context relevant to the idea. If neither is available,
degrade gracefully and continue on conversation alone — never stall or
error just because a lookup tool is missing.

## Step 2 — Detect multi-subsystem scope

Before drilling into details, check whether the described feature spans more
than one independent subsystem (more than one independent data flow or
deployment unit). If it does:

- Flag this immediately to the user, before asking detail questions.
- Propose splitting the work into separate per-subsystem change specs; each
  subsystem will run its OWN full `spec → plan → execute` cycle later.
- Each subsystem's own future explore session gets its own independent
  question budget (see Step 4) — subsystems never share one budget.

## Step 3 — Six-phase first-principles questioning (inline, no sub-agent dispatch)

See `references/first-principles-and-grillme.md` for the distilled method and
its sourcing. For every requirement-level assumption in the idea, work
through these six phases yourself, inline (do not dispatch a sub-agent for
this):

0. **Delete First** — ask whether this requirement should exist at all
   before optimizing it (this phase alone covers the "delete before
   optimize" instinct; there is no separate step for it).
1. **Problem essence** — what problem is this requirement actually solving?
2. **Challenge assumptions** — list the assumptions implicit in the user's
   statement that haven't been tested.
3. **Ground truths** — find the facts that can't be simplified further.
4. **Upward reasoning** — derive a solution only from the established ground
   truths from phase 3; don't skip steps.
5. **Verification** — trace the proposed solution back to phase 3's ground
   truths and confirm it still holds.

Make this reasoning visible in your replies (a reader should be able to see
phases 0-5 happening), not just performed silently.

## Step 4 — Batched, confirm-then-ask questioning

See `references/first-principles-and-grillme.md` for the distilled
grill-me-style technique and a worked example. Weave in a "restate to
confirm" technique on every round: before each batch
of questions, restate your current understanding of the requirement in one
sentence and ask the user to confirm or correct it, THEN ask the next batch.
This does not add extra rounds beyond the discipline below — it replaces a
bare question dump with one that opens with a recap.

- Ask in batches of **at most 4 questions per batch**.
- Soft total target: **at most 8 questions** for this change (this budget
  applies when Step 2's multi-subsystem split does NOT trigger). When truly
  unclear, prefer asking one more question over guessing.
- **Question-budget semantics**:
  - The 8-question soft target is a total across the whole session — you
    SHALL NOT unilaterally exceed it.
  - The user may request **+4 more** at any point; this is repeatable
    without limit, but only the USER can trigger an extension — you never
    grant yourself extra budget.
  - When Step 2 triggers a subsystem split, **each subsystem's own explore
    session gets its own independent ≤8 budget** (not shared, each also
    independently extensible by its own user), because each subsystem runs
    its own full spec→plan→execute cycle.

## Step 5 — Propose options

Present 2-3 concrete options with their tradeoffs, and recommend the one you
think is best, with reasoning.

**Optional**: you may attach a Mermaid mindmap to the handoff summary as a
thinking aid — this is non-authoritative, not verified, and never enters any
gate. See `templates/handoff-summary.md` for a complete worked example of the
handoff artifact, including a mindmap appendix and the "Rejected options"
section format used in Step 6 below.

## Step 6 — No files except the rejected-options exception

You SHALL NOT write any code or create any files unless the user explicitly
asks you to, with exactly one standing exception:

- **Artifact-language check first**: before writing anything into
  `spec.md`, check whether any artifact already exists in this change's
  directory with a `language:` frontmatter field. If one does, reuse that
  value — do not ask again. If this would be the very first artifact for
  this change, ask the user once (soft default `en`) and record the answer
  in this file's own `language:` frontmatter field for later artifacts in
  the same change to reuse (single source of truth: `STDD/spec.md`'s
  artifact-language rule). GWT keywords, `REQ-XX`/`S-XX` IDs, commands, and
  filenames are always English regardless of this field.
- At the end of explore, write the options you considered and rejected
  (each with a one-line reason) into a lightweight, non-gated section —
  `## Rejected options` — inside that change's `spec.md`.
  - This section is NOT part of the approval gate and NOT included in the
    two-file fingerprint calculation (see stdd-spec's gate rules).
  - If `STDD/<name>/spec.md` does not exist yet (explore ran before spec was
    written, the normal case), fold this rejected-options list into your
    handoff summary instead, and instruct that `stdd-spec` write it verbatim
    into `## Rejected options` when it creates the file.

## Step 7 — Recommend the next phase

- If the idea has a user-facing UI/interaction surface → propose calling
  `stdd-uiux` next.
- If it's purely backend/CLI with no UI surface → propose calling
  `stdd-spec` directly.

## Step 8 — Before handoff, run this checklist

Before ending the explore session and handing off, tick each item — it
guards the failure mode where a phase is silently skipped and no downstream
gate catches it (stdd-spec's Step 0 only re-checks entry triage, not that
explore's phases actually ran):

- [ ] **Entry triage applied**: for a change's first entry, the Step 0
      four-point check was run (or Step 0 was correctly skipped because a
      `STDD/<name>/` dir already existed).
- [ ] **Scope checked**: the Step 2 multi-subsystem check was done; if the
      feature spanned more than one subsystem, the split was flagged before
      any detail questions.
- [ ] **Six phases visible**: the Step 3 phases 0-5 (Delete First →
      Verification) are visible in the conversation, not performed silently.
- [ ] **Question discipline held**: questions came in batches of ≤4 opened by
      a restate-to-confirm; the ≤8 soft budget was not self-exceeded (only
      the user granted any +4 extension).
- [ ] **Options + recommendation**: Step 5 presented 2-3 tradeoff options with
      a recommended one and its reasoning.
- [ ] **Rejected options captured**: the considered-and-rejected list was
      written to `## Rejected options` in spec.md, or folded into the handoff
      summary for stdd-spec to write verbatim.
- [ ] **Next phase named**: Step 7 recommended stdd-uiux (UI surface) or
      stdd-spec (backend/CLI only).

## Notes for a fresh session

- This skill never calls `stdd-plan` or `stdd-execute` itself, and never
  writes a spec.md body itself (only the rejected-options note, per Step 6).
- If you can't tell whether serena/web-search/etc. are available, treat them
  as unavailable and degrade gracefully rather than erroring.

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
