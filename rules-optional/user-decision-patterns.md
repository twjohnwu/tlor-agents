---
version: 1.0.0
description: Decision patterns for AI-assisted development — how users actually decide
---

# user-decision-patterns.md — How the user actually decides (mined from real cases)

Audience: any session model. Decision patterns extracted from real
AI-assisted development workflows. Each pattern was observed in ≥2
corrections or logged decisions — these are not aspirations. When your
proposal conflicts with one of these, assume your proposal is wrong first.
Complements design-principles.md (system logic); this file is the USER's
logic.

## The three patterns

### D1. Spec before code — docs are the review checkpoint

Users in this pattern review the spec change to confirm the design, THEN
code gets written. For cross-cutting changes, contract/spec artifacts are
committed before code repos, even for tiny changes (removing a field,
relaxing a validator). **Apply**: when a change touches any spec/contract/
design doc, propose the doc diff first and wait for (or explicitly note)
confirmation before code. Exception: when a spec and ALREADY-SHIPPED code
disagree, code is authoritative — update the spec. D1 governs NEW changes,
not archaeology.

### D2. Single source of truth — never maintain a second copy

Users in this pattern reject convenience copies that will drift (e.g.
rejecting duplicating org guidelines inside a skill; trimming it to
reference the canonical doc instead). **Apply**: before duplicating any
content into a second location, propose a reference/link instead. If
duplication seems genuinely needed, that's a question for the user, not a
default.

### D3. Verify the measurement before trusting it; honest no-ops are valid

Real case: an optimizer scored 10 candidate descriptions identically at
floor (0/3 positives across 5 iterations). Instead of shipping the
"winner", the chosen response was a no-op with the tool's limitation
recorded. **Apply**: before acting on any score/benchmark/test signal,
check the signal can actually discriminate (do positives trigger at all?
does the test fail when it should?). "No change, because the measurement
had no signal" is a deliverable — say it plainly. (Same instinct as
judgment.md §4: a validation that includes a manual fix-up step masks real
bugs — simulate the clean second run.)

## Priority note

These patterns rank alongside judgment.md rubrics (see judgment.md if
installed): if a pattern and an explicit user instruction conflict, the
instruction wins; if a pattern and your own design taste conflict, the
pattern wins.

## Lessons

(append per maintenance.md format)
