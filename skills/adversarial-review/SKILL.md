---
name: adversarial-review
description: 'Multi-lens adversarial review — for major conclusions, architecture decisions, root-cause verdicts, or security judgments, dispatch the three opposition lenses (elf-archer, orc-saboteur, hobbit-gardener) in parallel to independently attack the conclusion; adopt it only if a majority survives. Triggers: "adversarial review", "多方抗辯", "抗辯", or any high-stakes judgment — irreversible operations, contract/schema changes, anything touching money or precision, architecture decisions, root-cause verdicts, production-affecting conclusions. Not for trivial edits or pure Q&A.'
---

# Adversarial review (multi-lens opposition)

> Ships with tlor-agents; the lenses are this plugin's `elf-archer`,
> `orc-saboteur`, `hobbit-gardener` (pinned opus since v1.2.0).

## Purpose

A single model checking its own conclusion systematically favors that
conclusion. This flow prevents "sounds right but is wrong" verdicts by
sending the conclusion to three independent sub-agents with different
lenses, whose default stance is to overturn it.

## Steps

1. **Assemble the review package** — one self-contained statement:
   - the conclusion itself (one sentence)
   - the evidence it rests on (file:line, test output, measurements)
   - the blast radius (what changed, who depends on it)
   - If the subject is N independent findings (e.g. a review report's
     items): adjudicate each finding separately — never bundle them into
     one aggregate conclusion; bundling dilutes per-finding resolution.

2. **Dispatch all three lenses in ONE message** (Agent tool,
   subagent_type `elf-archer`, `orc-saboteur`, `hobbit-gardener` —
   parallel, never serial, never merged into a single agent). Each
   prompt = the review package verbatim + that lens's task. Model: the
   lenses are pinned `opus` in frontmatter — do NOT pass a
   `model: sonnet` downgrade inside this flow (the downgrade exists for
   routine convenings; adversarial review is by definition not routine).
   If the producing model ran above opus, state the rigor gap honestly
   in the final report. Per-finding cost is 3 sub-agents; cap 6 parallel
   sub-agents per round = at most 2 findings per batch; further findings
   go in later batches, reported separately, never merged.

3. **Verdict (majority-survival)**:
   - 3/3 SURVIVED → confirmed; adopt.
   - 2/3 SURVIVED → confirmed, but the REFUTED lens's reasons MUST be
     listed as risks in the user report.
   - ≤1/3 SURVIVED → conclusion BLOCKED; revise per the REFUTED reasons
     and re-submit.

4. **Loop-until-dry for critical conclusions**: anything affecting
   production, data safety, contracts/schemas, or money/precision —
   after revision, re-review until 2 consecutive rounds produce no new
   REFUTED reason. If you cannot clearly rule those impacts out, treat
   it as critical. Feed already-adjudicated reasons into the next
   round's prompts to avoid re-discovery. All other conclusions: one
   round of three lenses suffices.

5. **Report format** (the final message must include):

   | Lens | Verdict | Key reason |
   |---|---|---|
   | elf-archer | … | … |
   | orc-saboteur | … | … |
   | hobbit-gardener | … | … |

   Plus one line: `Adversarial result: N/3 survived → confirmed / blocked (reason)`.

## Never

- Skip a lens to save time.
- Merge the three lenses into one agent — independence is the premise.
- Swallow a REFUTED reason silently; report it or fix it.

---
Convening flow inspired by [Miguok/fable-harness](https://github.com/Miguok/fable-harness) (MIT).
