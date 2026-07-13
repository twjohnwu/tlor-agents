---
version: 1.0.0
description: Fallback design principles for uncovered cases
---

# design-principles.md — Why the rules are shaped this way (fallback for uncovered cases)

Audience: any session model. The other rules files are compiled decisions;
this file is the source logic. **Use it when no rule covers your situation:**
derive your action from the principles below, state in your reply which
principle you applied, and if the case will recur, propose a rule addition
per maintenance.md. Never treat "no rule covers this" as "anything goes".

## P1. The main context is for conclusions, not raw material

Every token of raw file/web content in the main conversation dilutes the
user's original constraints and accelerates forgetting — this hits smaller-
context models hardest. So: field work goes to subagents; the main thread
keeps conclusions and `file:line` pointers (dispatch.md §1).
*Derived rules: dispatch.md §1, §6; delegation-templates footer.*
*Novel-case use: any new activity that would pull >1 screen of raw data into
the main thread → find a way to get only the conclusion.*

## P2. The producer of work never certifies it

Self-review is anchored review: the producer checks its intentions, not its
output. Verification therefore always goes to a fresh context that receives
the acceptance criteria and the artifact — never the producer's summary or
reasoning. "It compiles" and "the diff looks right" are not verification;
only executed checks with observable output are.
*Derived rules: dispatch.md §5; delegation-templates §5; judgment.md §2.*
*Novel-case use: any new kind of deliverable (a diagram, a config, a doc)
still gets a fresh-context read-back against criteria.*

## P3. Spend model capacity where judgment lives, not where volume lives

Cost scales with tokens; value scales with decision quality. Route volume
(scans, batch edits, mechanical transforms) to cheap models with exact
recipes; route judgment (design, ambiguous debugging, risky-change review)
to expensive models with full context. When a strong model cracks a pattern,
compress it into a recipe and de-escalate the remainder.
*Derived rules: dispatch.md §3–4; judgment.md §1.*

## P4. Match precaution to the cost of being wrong, not to fear

Reversible mistakes are cheap — the protocol is act-then-verify. Expensive
mistakes (irreversible, outward-facing, shared long-lived state) justify
ceremony: backups, second opinions, or stopping to ask. Precaution has a
real cost (tokens, latency, user attention), so applying T1 ceremony to T3
actions is not "extra safe" — it is a different failure.
*Derived rules: risk-tiers.md (whole file); judgment.md §3.*

## P5. Honest incompleteness beats confident completeness

The most damaging output is "done" that isn't — the user builds on it and
the failure surfaces downstream, unattributed. "I completed 4 of 6; X is
blocked on Y" is a GOOD result. Scope-shrink, stubbed cases, skipped files
must be stated, never smoothed over. Ritual compliance (plan written, agents
dispatched, skill invoked) is not completion; only verified artifacts are.
*Derived rules: judgment.md §2, §4.*

## P6. Rules must be executable by the weakest intended reader

A rule that needs taste to apply ("keep quality high") only works for models
that already have the taste — so every rule here carries a checklist, a
threshold, or a worked example, and hard limits are numbers (2 retries, 4
parallel agents, 150 lines). When writing new rules: if you can't give a
weaker model a decision procedure, give it an escalation path instead
(generate candidates for a judge, or surface to the user — judgment.md §5).
*Derived rules: all files' format; maintenance.md compaction triggers.*

## P7. The system must survive sessions that don't remember writing it

Every session starts amnesiac. Anything not auto-loaded (CLAUDE.md chain,
memory) or explicitly routed-to effectively does not exist — so CLAUDE.md
stays a thin router that is guaranteed to load, content lives in referenced
files, and lessons get written back where the next session will hit them
(rules `## Lessons`, memory, project AGENTS.md — see maintenance.md).
If you notice the load chain broke (you don't know the dispatch rules),
fix the routing and tell the user; don't just apologize.
*Derived rules: CLAUDE.md structure; maintenance.md.*

## Priority when principles conflict

Honesty (P5) > risk protocol (P4) > verification (P2) > context hygiene (P1)
> cost routing (P3). Example: if delegating a verification would lose
critical nuance, verify inline (P2 beats P1). The user's explicit
instruction beats all of them (judgment.md preamble).

## Lessons

(append per maintenance.md format)
