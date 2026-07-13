---
version: 1.0.0
description: Fill-in dispatch prompt templates for the five standard delegation shapes
---

# delegation-templates.md — Fill-in prompts for the Agent tool

Copy the template, fill every `{{slot}}`, delete unused optional lines. Every
template already embeds the three-part contract (goal+why / acceptance /
report format) from dispatch.md §2 and the report contract §6. Dispatch
targets are the pinned tlor-agents roles (dispatch.md §3 table); each header
below names the role and the generic fallback for when a role doesn't fit.

Shared footer — append to EVERY dispatch:

```
Report contract: your final message is data for the orchestrator. Return
(1) conclusions in ≤5 bullets, (2) file:line for every claim, (3) paths of
files you wrote, (4) anything you could not verify, stated explicitly.
No file-content dumps >10 lines.
```

---

## 1. Search / locate  (role: rohirrim-outrider for targeted, ranger-pathfinder for broad; fallback: built-in search + explicit model)

```
Goal: find {{what}} in {{scope, e.g. src/}}.
Why: {{what the orchestrator will do with the answer}}.
Check these forms too: {{synonyms / naming conventions / config vs code}}.
Acceptance: every hit reported as file:line + one-line role description;
say explicitly if you found nothing (and list where you looked).
```

## 2. Implementation  (role: gondor-builder; `model: opus` override if judgment is heavy; design decisions stay with the Maia)

```
Goal: implement {{feature/change}} in {{files/dir}}.
Why: {{user-visible motivation}}.
Context you need: {{key facts, existing utilities to reuse with paths,
constraints from project conventions that apply}}.
Steps: {{ordered steps if the pattern is known; omit if the agent should design}}.
Acceptance:
- {{behavioral criterion, checkable, e.g. "POST /convert returns 422 on empty file"}}
- {{command}} passes ({{e.g. go test ./...}})
- Code matches neighboring style (judgment.md §5 floor)
Do NOT: {{forbidden moves, e.g. touch generated files, add dependencies}}.
NON-GOALS: {{explicitly out of scope — no drive-by refactors/fixes}}.
ALLOWED PATHS: read {{globs}}; write {{globs}} — anything else is out of scope.
STOP CONDITIONS: an out-of-scope file needs changing, any deletion, or a
secret/credential encountered → STOP and report; do not improvise.
```

## 3. Refactor / batch change  (role: dwarf-smith; `model: haiku` override if the recipe is trivially exact)

```
Goal: apply this exact transform to {{file list}}.
Why: {{motivation}}.
Recipe (already validated on {{example file}}):
{{before/after snippet or precise rule}}
Acceptance: all listed files transformed; {{build/test command}} still passes;
zero behavior change intended — flag any file where the recipe doesn't fit
INSTEAD of improvising.
NON-GOALS: {{explicitly out of scope — no drive-by refactors/fixes}}.
ALLOWED PATHS: read {{globs}}; write {{globs}} — anything else is out of scope.
STOP CONDITIONS: an out-of-scope file needs changing, any deletion, or a
secret/credential encountered → STOP and report; do not improvise.
```

## 4. Research  (role: noldor-loremaster; `model: opus` override for conflicting-source synthesis)

```
Goal: answer "{{question}}".
Why: {{decision this feeds}}.
Sources: {{docs/URLs/library docs; or "search the web"}}.
Acceptance: direct answer first, then evidence with source links/versions;
distinguish "documented fact" from "inference"; note version applicability
({{our stack/version}}); if sources conflict, show both and say which is
newer/authoritative.
Write findings >30 lines to {{<scratchpad>/path}} and return the path.
```

## 5. Review / verification  (role: eagle-sentinel — pinned opus for risky changes, add `model: sonnet` for routine read-backs; high-risk verdicts add the panel elf-archer/orc-saboteur/hobbit-gardener)

```
Goal: verify {{artifact: diff / files / claim}} against the acceptance
criteria below. You are a fresh-context checker: judge only what you can
see and run, not intentions.
Acceptance criteria to check, one by one:
{{numbered list — same list the producer was given}}
For code: actually run {{test/build command}} and quote the result.
Verdict format: per criterion PASS/FAIL + evidence (file:line or command
output); overall verdict; list anything that smells wrong even if outside
the criteria (mark those "advisory").
For docs/rules files: check that every path, command, and section reference
mentioned in the artifact actually exists — quote what you checked.
Do not trust the producer's summary — it is not included on purpose.
```

---

## Slot-filling rules (for weaker orchestrators)

1. Can't fill the ACCEPTANCE slot? The task is underspecified — go back to
   decomposition/clarification; do NOT dispatch with a vague criterion.
2. One dispatch = one goal. If your Goal line contains "and", split it.
3. Independent dispatches go in ONE message (parallel tool calls).
4. Keep the filled prompt under ~60 lines (decomposition.md §4); paste facts
   the agent needs verbatim — it cannot see this conversation.
5. NON-GOALS / ALLOWED PATHS / STOP CONDITIONS apply to write-capable
   dispatches (templates §2/§3); read-only templates (§1/§4/§5) default to
   whole-repo read, write nothing — no need to spell them out.
