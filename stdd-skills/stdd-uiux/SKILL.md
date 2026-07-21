---
name: stdd-uiux
description: 'STDD UI/UX design phase — narrative title "Lórien 精靈美學" (the design eye of Lothlórien). Conditional stage inserted between stdd-explore and stdd-spec only when a change has a user-facing UI surface: gathers design references, generates design-ux.md (MASTER + per-page/flow override structure), runs a mechanical anti-pattern self-review, and owns the reflow protocol when a later stage finds a UX defect or conflict. Triggers: "/stdd-uiux", any STDD change with a screen/interaction surface.'
---

# stdd-uiux — Lórien 精靈美學

Opt-in skill (installed from `stdd-skills/`, not auto-loaded from the
plugin's `skills/` directory). Conditional stage: `explore → uiux → spec`
only when the change has a UI surface; purely backend/CLI changes skip
straight to `explore → spec`.

## Step 1 — Decide whether this change needs this skill at all

Whether handed off from `stdd-explore` or called directly, first decide if
this change has a UI surface (a user-visible screen or interaction):

- **Has a UI surface** → continue to Step 2.
- **Purely backend/CLI/no UI** → you SHALL NOT produce `design-ux.md`;
  recommend calling `stdd-spec` directly instead, and STOP.
- **Unsure** → ask the user; never guess.

## Step 2 — Derive a requirements checklist (before gathering references)

Before asking any design-reference question, derive a requirements checklist
from the available inputs — the user's request for this change plus any
upstream artifact (e.g. `stdd-explore`'s handoff summary) — and record it:

- Fold it into your working notes for now; no new file convention is
  prescribed for this intermediate state. Once `design-ux.md` is created in
  Step 5, move this checklist verbatim into that file's requirements-checklist
  appendix section.
- At skill wrap-up (Step 7, after the anti-pattern self-review, before
  presenting for approval) you SHALL check off every item on this list one by
  one and explicitly list any item that is NOT met — never silently treat an
  unmet item as passed.

## Step 3 — Batched design-reference gathering (with Figma MCP graceful degrade)

Once confirmed the change has a UI surface, gather design references in
batches, soft target **at most 6 questions**, asking about: Figma links,
screenshots, brand-guideline documents, preferred reference examples — ask
rather than guess.

- If the user provides nothing for a given item, explicitly record "no
  reference provided, using default judgment" — never pretend a reference
  was supplied when it wasn't.
- **Figma MCP detection**: if the user supplies a Figma link, check whether
  a Figma MCP tool is available (same detect-then-degrade pattern as any
  optional tool):
  - Available → read the referenced design content to help produce
    `design-ux.md`.
  - Not available → gracefully degrade: record the link as a manual
    reference and note the degrade reason. Never stall or error just
    because the MCP tool is missing.

## Step 4 — Design-guideline detection (do this before generating design-ux.md)

At the start of this phase:

- Check whether the target project's `wiki/design_guideline/` directory
  already exists, AND ask the user whether a separate design-guideline
  document exists elsewhere (unsure → ask, never guess, same rule as Step 1).
- **Guideline already exists** (in `wiki/design_guideline/` or supplied by
  the user) → that guideline is this project's canonical global design
  standard. This change's `design-ux.md` MASTER section SHALL become "cite
  the guideline + record only this change's delta" — never duplicate the
  guideline's full text.
- **No guideline exists** → the LAST step of this skill's run (Step 8 below)
  SHALL generate a general-purpose design guideline into
  `wiki/design_guideline/` from this session's output, for reuse by future
  features in this project. Follow the `wiki/` taxonomy and the
  `wiki/README.md` routing-table rule described in Step 8.

## Step 5 — Generate `design-ux.md`

Once references are gathered (or the user explicitly skips them), create
`STDD/<name>/design-ux.md`. A complete worked example lives in
`templates/design-ux.md` — use it as the format reference; don't skip
straight to freeform prose.

- **Frontmatter**: this file's frontmatter carries `change: <name>`,
  `type: design-ux`, and `language: <code>` — no `status` field, no
  fingerprint field of any kind. The one and only home for its fingerprint is
  that change's `spec.md` frontmatter field `design_ux_fingerprint` (computed
  at approval time by `stdd-spec`).
- **Artifact language**: before writing, check whether this change already
  has an existing artifact (e.g. a prior `spec.md` from a re-entry, or a
  handoff note) with a `language:` frontmatter value:
  - Already set → reuse that value, don't ask again.
  - Not yet set (this is the first artifact for this change) → ask the user
    once (soft default `en`, any language code is acceptable), and write the
    decision into this file's `language:` field so later artifacts in the
    same change (`spec.md`, `plan.md`) can reuse it.
  - GIVEN/WHEN/THEN, `REQ-XX`/`S-XX`, commands, and filenames stay English
    regardless of this setting (see `STDD/spec.md`'s artifact-language
    section — single source of truth, not restated here).
- **Body structure**: MASTER (global) section + per-page/per-flow override
  sections. Mark any section that doesn't apply as `N/A` rather than
  omitting it silently. Sections to include:
  - User flows (as a Mermaid flowchart)
  - Information architecture
  - Layout (markdown tables/blocks as sketches)
  - Component hierarchy
  - Design tokens (color, typography, spacing)
  - States: empty, error, and loading
- Every section SHALL cite the relevant `REQ-ID`(s) it supports.
- If a project canonical design guideline was found in Step 4, the MASTER
  section here is "cite guideline + delta only" per that step — don't repeat
  it.
- **Few-shot corpus discipline**: if you need an external few-shot design-doc
  example to help produce this file, load **at most 1-2 examples per
  session** — never load an entire example corpus into context.

## Step 6 — Optional HTML/CSS prototype

Only if the user explicitly asks for a visual prototype (never produce this
proactively):

- Write files under `STDD/<name>/prototype/`.
- The first line of every file in that directory must clearly state: this
  directory is NOT product code, is excluded from TDD coverage counting, and
  exists purely for visual communication.

## Step 7 — Anti-pattern self-review and requirements-checklist close-out

After `design-ux.md` (and any optional prototype) exists, mechanically scan
against this checklist — report every item's status, don't just eyeball it.
`references/anti-pattern-checklist.md` ships a distilled version of this same
list with common-mistake notes per item; use it as a quick-scan aid instead
of re-deriving the list from scratch.

1. Is text/background contrast adequate (qualitative WCAG AA description)?
2. Are touch targets too small (mobile tappable area)?
3. Is the empty state explicitly defined?
4. Is the error state explicitly defined?
5. Is the loading state explicitly defined?
6. Does it look like generic "AI-default" design (gratuitous gradient cards,
   meaningless nested cards)?
7. Is component spacing/alignment backed by explicit design tokens, rather
   than ad-hoc numbers?
8. Does color usage carry clear semantic meaning (not decorative misuse)?
9. Is typographic hierarchy consistent (clear distinction between
   heading/body/caption)?
10. Are interaction states (hover/focus/active/disabled) at least listed?

State explicitly in your report: **this checklist is a floor, not a taste
ceiling** — passing it means known common mistakes were avoided, not that the
design "looks good."

Only after both of the following are done do you move to presenting the file
for approval:

- Every item above reported with a status.
- Step 2's requirements checklist checked off item by item, with any unmet
  item explicitly listed — never silently treated as passed.
- **Disposition of unmet items**: any unmet item is handed back to the
  orchestrating main session (Maia) to re-design and dispatch corrective
  work orders. Only when the main session cannot adjudicate (a
  requirement-level ambiguity, or mutually exclusive trade-offs) does it ask
  the user.

## Step 8 — wiki/ writes (only when Step 4 found no existing guideline)

If Step 4 determined no guideline exists yet, generate one into
`wiki/design_guideline/` now, following the project's fixed `wiki/`
taxonomy (`design_guideline/`, `reference/`, `standard/`, `coding_standard/`,
`knowhow/`, `cases/` — unsure which bucket → default to `reference/`; a new
top-level category requires explicit user consent). Every `wiki/` file gets
a frontmatter with `source`, `date`, `tags`.

**README routing-table rule**: any write into `wiki/` SHALL first check
whether `wiki/README.md` exists — create it if missing — and register the
new file into its routing table (relative path + one-line purpose). Never
re-register an entry that's already listed.

## Step 9 — Reflow protocol (S-25): a later stage finds a UX defect or conflict

`stdd-spec`, `stdd-plan`, or `stdd-execute` (including their own adversarial
review steps) may discover that a requirement changes an already-approved
UX decision, or that the UX design itself has a defect. When that happens,
this skill (`stdd-uiux`) is the one that handles it:

1. **STOP the originating stage** — no further spec/plan/code writing until
   `design-ux.md` is updated. This applies no matter which of the three
   stages found the problem.
2. **Cross-role honesty check**: if the current execution environment does
   NOT have `stdd-uiux` installed (e.g. an RD-only view), that role SHALL
   STOP and report "this needs a role with `stdd-uiux` installed (UIUX or
   ALL view) to update design-ux.md" — it SHALL NOT rewrite
   `design-ux.md` itself.
3. **Check rejected options first**: before proposing any new approach for
   the affected delta, read the change's `spec.md` rejected-options section
   (written by `stdd-explore`) so you don't re-propose something already
   rejected. That section's heading text follows `spec.md`'s own
   `language:` value per the artifact-language rule (`STDD/spec.md`,
   artifact-language section) — locate the section by its purpose (the
   rejected-options list), not by assuming a fixed literal heading string.
4. Update only the affected delta in `design-ux.md` (no need to rerun the
   full Steps 1-7 from scratch).
5. **Hard cap, 3rd trigger on the same region**: if this reflow protocol
   fires a 3rd time on the same `design-ux.md` region (same section or
   override block), STOP doing incremental delta patches on that region.
   Instead, present the whole `design-ux.md` for a full re-review and let
   the user decide: keep as-is, do a major rewrite, or re-run the full
   Steps 1-7. Never keep patching the same region indefinitely.
6. **Delta-only rescan**: below the hard cap, after the delta update, rerun
   only Step 7's anti-pattern scan on the sections that changed — no need to
   rescan the whole file.
7. **Convergence proposal**: if the same design pattern shows up in 3+
   override sections during this reflow, propose (don't unilaterally do)
   consolidating it into `wiki/design_guideline/` per Step 8's rules. Leave
   the decision to the user; if declined, leave `design-ux.md` as-is.
8. **Fingerprint + re-approval sync** (regular path, not the backfill path
   below): once the delta update + rescan are done:
   a. Recompute `design-ux.md`'s content fingerprint using `stdd-spec`'s
      extraction rule (content after the second `---`, `shasum -a 256`) and
      update that change's `spec.md` frontmatter `design_ux_fingerprint`.
   b. Ask the user for a **lightweight re-approval** — just confirming this
      UX delta (not a full re-approval); this does NOT re-trigger the
      3-lens adversarial panel from `stdd-spec` unless the delta involves a
      REQ-level change (single source of truth for panel scaling is
      `stdd-spec`'s own gate step).
   c. Only after (a) and (b) are done do you move to "resume" below — this
      prevents an updated `design-ux.md` whose fingerprint was never synced
      from silently failing the `stdd-execute` boundary gate later.
9. **Backfill path** (a different situation: spec was already approved but
   `design-ux.md` was never created because UI-ness was misjudged earlier):
   create `design-ux.md` first → compute and write
   `spec.md`'s `design_ux_fingerprint` per the same extraction rule → roll
   `spec.md`'s `status` back to `draft` and re-run the full approval gate.
10. **Hand back**: once delta + fingerprint + re-approval are complete, this
    skill reports back to the originating stage (e.g. RD) to resume its own
    phase skill — the gate only reads artifact state, so resuming is enough.
11. Resume the original spec/plan/code-writing work.
12. Record this reflow event and its reason in your report.

## templates/ and references/

- `templates/design-ux.md` — a complete worked example of `design-ux.md`:
  frontmatter (`change`/`type`/`language`), MASTER + override structure, a
  Mermaid `flowchart` example for user flows, and a requirements-checklist
  appendix. Use it as the format to follow in Step 5, not something to copy
  verbatim into a real change.
- `references/anti-pattern-checklist.md` — the same 10-item checklist as
  Step 7, distilled with a one-line common-mistake note per item, for a
  quick scan pass instead of re-deriving the list.

## Notes for a fresh session

- Never write `status` or any fingerprint field into `design-ux.md` itself —
  those live only in `spec.md`.
- Never skip the anti-pattern self-review report before requesting approval.
- Never silently rewrite `design-ux.md` from a role that doesn't have this
  skill installed.
- Never silently mark an unmet requirements-checklist item as passed —
  Step 7 requires listing it explicitly.

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
