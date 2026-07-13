---
version: 1.0.0
description: How to split a task into dispatches before delegating to subagents
---

# decomposition.md — How to split a task before dispatching

Audience: the main-conversation model. Read this BEFORE writing any dispatch
prompt. dispatch.md tells you that you must delegate; this file tells you how
to cut the work into dispatches. Companion rubrics: judgment.md; risk levels:
risk-tiers.md.

## 1. First decision: does this task need splitting at all?

A task fits in ONE dispatch when ALL of:
- [ ] One agent can hold everything it needs (the prompt + a few named files)
      without discovering scope as it goes
- [ ] It has ONE acceptance criterion set (one "done" definition)
- [ ] Expected output is one artifact (one report, one diff, one file)

If any box is unchecked, split. If all are checked, dispatch it whole — do
not split for the sake of splitting; every extra agent costs integration
work and adds a place for information to get lost.

**Too big for one dispatch**: "implement the export feature" (design decisions
+ multiple files + tests = several done-definitions).
**Too small to be its own dispatch**: "rename this variable in one file" —
fold it into a neighboring subtask or do it inline (dispatch.md §1 MAY list).

## 2. How to cut: by acceptance criterion, not by file

Each subtask = one independently checkable outcome. Write the acceptance
criterion FIRST; if you cannot state one for a fragment, it is not a valid
subtask — merge it into one that has one.

Standard cut sequence for feature work:
1. **Locate/understand** (search, read-only) → conclusions + file:line.
   Search-first is the default ONLY when you don't already know where the
   change lands: user named the exact files → skip straight to implement;
   "somewhere in the upload path" → search first. Searching what you
   already know wastes a dispatch; implementing where you only guess wastes
   two.
2. **Decide** (only if real design choices remain — opus, or ask user per
   judgment.md §3) → a written decision
3. **Implement** (one dispatch per independent change area) → diff + passing command
4. **Verify** (fresh context, per dispatch.md §5) → verdict with evidence

Steps 1→2→3→4 are sequential by nature (each consumes the previous output).
Parallelism lives INSIDE a step, never across steps.

**Executor-naming gate (L1 of "the Maia does no field work").** Every step of
a written dispatch plan MUST name its executor: a role from dispatch.md §3
(rohirrim-outrider, ranger-pathfinder, noldor-loremaster, dwarf-smith,
gondor-builder, eagle-sentinel, or a panel lens), or a generic subagent with
an explicit `model`. A step with no named executor defaults to "dispatch it",
never "the Maia does it inline". The name **"Maia" (the main session) may
appear only in these four slots**: decomposition, integration/reconciliation,
talking to the user, and the dispatch.md §1 MAY-do-inline exceptions. Before
ExitPlanMode — or before running an approved-but-unplanned batch — scan the
plan: any field-work step whose actor is the Maia is a bug, re-assign it to a
role. (L2 backstop: the PreToolUse hook blocks main-session edits to
institution files outright.)

## 3. Parallel vs sequential — dependency checklist

Two subtasks may run in parallel ONLY if ALL of:
- [ ] Neither needs the other's output (no data dependency)
- [ ] They will not edit the same file (no write conflict; parallel READS are fine)
- [ ] A wrong result in one does not invalidate the other's work

If any box fails → sequential, and the later prompt must embed the earlier
result (paste conclusions in; the new agent has no memory of the old one).

**Parallel example**: "survey how errors are handled in project A" +
"survey how errors are handled in project B" — different dirs, read-only,
independent conclusions. Dispatch both in one message.
**Sequential example**: "find where uploads are validated" then "add a size
limit to that validation" — the second needs the first's file:line. Never
guess the location to fake parallelism.
**Common error**: implementing and writing tests for the same function in
parallel. Both edit adjacent code and both depend on the same interface
decision; if the interface shifts during implementation, the test agent's
work is garbage. Sequence them, or make one agent do both.

## 4. Sizing and count limits

- **Per-batch cap: 4 parallel agents.** More than 4 means your integration
  step becomes its own hard task; batch the rest after the first wave returns.
- **Per-agent scope cap**: one agent should touch at most ~5 files for edits
  or ~1 project directory for surveys. Bigger → cut again.
- **Depth cap**: aim for a task tree at most 2 levels deep (your dispatches;
  no sub-sub-planning). If a subtask needs its own decomposition, it was cut
  too big — re-cut at your level, because you can't supervise what you can't see.
- **Prompt-length signal**: a filled dispatch prompt over ~60 lines means the
  subtask is too big — cut again. Two subtasks sharing >50% of their context
  files with no ownership boundary between them → merge into one.
- **Scale check**: a typical one-feature task lands at 3–4 dispatches
  (explore, implement ×1–2, verify). 8+ dispatches = cut too fine (integration
  overhead dominates); 1 giant dispatch = you skipped cutting.

## 5. Integration is the commander's job

After parallel results return:
- Reconcile conflicts yourself (two agents describing the same code
  differently → read that one spot inline, or send one targeted follow-up).
  Never average conflicting claims — resolve or escalate them.
- Never assume agents saw each other's output. Anything agent B must know
  from agent A goes INTO B's prompt verbatim.
- Re-read the ORIGINAL user request after integration and diff it against
  what you have — decomposition loses requirements at the seams; this
  re-read is where you catch the dropped ones (judgment.md §2 no-silent-scope-shrink).

## 6. While agents run / when results come back wrong

- **While waiting**, the orchestrator may ONLY: draft the next dispatch
  prompts, write status for the user, answer the user. It MUST NOT run the
  same search/read "in the meantime" — that duplicates the agent's work and
  floods the main context with exactly what delegation was avoiding.
- **Partial failure**: hand off ONLY the failed subset to the next tier
  (dispatch.md §4); completed subtasks stand. Exception: if the failure
  reveals a wrong shared assumption, treat completed work as suspect too —
  that's a wrong-direction signal (judgment.md §4), not a mechanical retry.
- **Re-plan triggers** — stop dispatching and re-cut the plan when ANY of:
  (1) judgment.md §4 fires; (2) scope has grown to ~2× the original cut;
  (3) an explore report invalidates an assumption the plan was built on.

## 7. Worked contrast

Task: "add a CSV export option to an existing XLSX export feature."

**Bad cut** (by file): agent1 "edit the exporter module", agent2 "edit the
routes", agent3 "edit the frontend download button" — in parallel. No one
owns the CSV format decision; the three guess differently; integration fails.
**Good cut** (by outcome, sequential where dependent; each step names its executor):
1. ranger-pathfinder: "map the existing XLSX export path end-to-end (backend
   format layer → route → frontend trigger), return file:line chain"
2. gondor-builder: "add CSV alongside XLSX at these points: {file:line chain};
   acceptance: the app starts + a request to the convert endpoint with
   `format=csv` returns a valid CSV; existing XLSX tests still pass"
3. eagle-sentinel (model: sonnet): run the acceptance commands, per dispatch.md §5.
The frontend button, if needed, is step 2b AFTER the API shape from step 2
is fixed — it depends on the response contract.

## Lessons

(append per maintenance.md format)
