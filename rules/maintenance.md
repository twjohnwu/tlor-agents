---
version: 1.0.0
description: What sessions may change in this rule system on their own, and what needs human approval first.
---

# maintenance.md — How sessions update this rule system safely

These rules protect the installed framework. Sessions maintain them; they
don't own them.

## What you may change on your own

- **Fixing verified facts**: a path/tool/command in any rules file or
  project instruction file (AGENTS.md or equivalent) that you have CONFIRMED
  is wrong. Verify first, then fix, then note the change in your session
  summary to the user.
- **Adding lessons**: new pitfalls and their fixes, per the format below.
- **Adding routing rows** to the routing file's table (CLAUDE.md or
  equivalent) when a new rules file exists.
- **Project instruction files (AGENTS.md or equivalent)**: normal edits as
  projects evolve.

## What requires asking the user first

- Changing the model dispatch table or escalation thresholds
- Weakening any rule (turning MUST into MAY, raising retry caps, removing a
  verification step) — including "just this once" exceptions
- Deleting a rubric, template, or a diagnosis/reference file
- Restructuring the file layout or moving files out of the rules directory
- Anything in the routing file's non-negotiable rules section

Rule of thumb: making the system stricter or more accurate = self-serve;
making it looser = user decision.

## Where lessons go

1. **Recurring workflow failures** (a dispatch pattern that misfires, a
   judgment call the rubrics got wrong) → append to the `## Lessons` section
   at the bottom of the relevant rules file, format:

   ```
   - YYYY-MM-DD (model): symptom → root cause → rule adjustment made/proposed
   ```

   If the lesson demands a rule change that falls in the ask-first list,
   record it as `proposed:` and raise it with the user.
2. **Project-specific gotchas** → that project's instruction file (AGENTS.md
   or equivalent).
3. **One-off environment/user facts** → whatever persistent memory mechanism
   the host tooling provides, if any.

After ANY edit to rules or routing/instruction files: dispatch one fresh-context
verification pass to read the changed files and report contradictions,
references to paths/sections that don't exist, and sentences a reader
without session context would misread.

## Compaction triggers

- Any single rules file > 150 lines, or instruction files > 100 lines, or
  the routing file > 40 lines → compact: merge duplicate lessons into the rule body, extract
  detail into a referenced file, delete superseded entries. Keep a dated
  `.bak-YYYYMMDD` copy beside the file before compacting.
- A `## Lessons` section > 10 entries → fold the stable ones into the rules
  proper and delete the entries.

## Invariants (never break during maintenance)

- Back up before rewriting any existing file (`cp X X.bak-YYYYMMDD`).
- The routing file (CLAUDE.md or equivalent) stays a thin router — content
  lives in referenced files.
- Every file the routing file references must exist (no dead links) — check
  after any rename/delete.
