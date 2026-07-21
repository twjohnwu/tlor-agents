---
description: Externalized judgment rubrics for escalation, done-ness, asking the user, wrong-direction signals, and quality floor
managed-by: tlor-orchestration  # plugin-managed, do not edit; overrides go in rules/customize/
audience: all
---

# judgment.md — Externalized judgment rubrics

Five rubrics for calls that stronger models make by instinct. Each has a
trigger checklist, a positive example (do act) and a negative example (don't).
If a rubric and the user's explicit instruction conflict, the user wins.

## 1. When to escalate the model

Escalate (per dispatch.md §4) when ANY of:
- [ ] The same subtask has consumed two retry rounds at the current tier
- [ ] The task requires weighing trade-offs with no checkable right answer
      (API shape, architecture, naming a public interface)
- [ ] You notice you are pattern-matching ("this looks like X") without being
      able to state WHY the pattern applies here
- [ ] The cost of being wrong exceeds the cost of the stronger model
      (data migration, anything touching `main`, anything the user ships)

**Positive example**: sonnet subagent twice returned a "fix" for a flaky Go
test that just widened a timeout. Escalate to opus with both attempts attached
— the real cause is likely a race, which needs reasoning, not retries.
**Negative example**: haiku formatted 18 of 20 files correctly and choked on
2 with unusual syntax. Don't escalate the whole batch to opus — send just the
2 stragglers to sonnet.

## 2. When work is actually done

"Done" requires ALL of:
- [ ] Every acceptance criterion checked individually — by re-reading the
      criteria list, not from memory
- [ ] Verification per dispatch.md §5 actually ran (fresh read-back, tests
      executed, output observed) and you can quote its result
- [ ] Bug-fix claims carry fail-then-pass evidence: the test/repro was RED
      before the fix and GREEN after — a test that was never red proves nothing
- [ ] No silent scope-shrink: if you did less than asked (skipped a file,
      stubbed a case), it's stated explicitly in the report
- [ ] Nothing in the final state contradicts a rule in CLAUDE.md/AGENTS.md

**Positive example**: "All 6 files written; fresh sonnet agent read each back
against the criteria list — 6/6 pass; `go test ./...` exits 0 (output quoted
above)." That is done.
**Negative example**: "I've implemented the parser and it should handle all
the edge cases now." No test run, "should" — not done. Declaring done without
verification is the single most damaging failure mode.

## 3. When to stop and ask the user

(For state-changing actions, classify the risk tier first — `risk-tiers.md`;
T1 actions always land in "ask".)

Ask when ANY of (and batch the questions — one interruption, not five):
- [ ] Two or more materially different interpretations of the request exist,
      and picking wrong wastes >15 min of work or touches anything public
- [ ] The action is irreversible or outward-facing (force-push, delete,
      publish, send, spend money) and wasn't explicitly requested
- [ ] You'd have to invent a fact you cannot verify (credentials, a URL, a
      business rule, "what the user probably meant" about their own data)
- [ ] Completing the task requires violating a rule in CLAUDE.md/AGENTS.md
- [ ] Secrets/credentials are involved beyond "leave them where they are" —
      never commit them, redact them in reports, and ask before moving,
      rotating, or copying them anywhere

Do NOT ask when the answer is derivable from the repo, git history, memory
files, or a cheap experiment — go find out instead.

**Positive example**: "Clean up the old scripts" and there are two script
dirs, one of which is referenced by a cron-looking file. Ask which — deletion
is irreversible.
**Negative example**: Asking "should I use the existing test helpers?" when
the repo obviously has them and every existing test uses them. That answer
was derivable; asking it erodes the user's trust in your autonomy.

## 4. Wrong-direction signals — change course, don't retry

If ANY of these fire, STOP retrying. Re-read the original request, write down
your current hypothesis in one sentence, and either re-frame or escalate:

- [ ] Each "fix" spawns a new error in a different place (whack-a-mole)
- [ ] You are about to add a special case for the second time in the same fix
- [ ] The diff keeps growing but the acceptance criteria checked-off count
      doesn't
- [ ] You're modifying code you don't understand to make a symptom disappear
- [ ] The current approach requires disabling/weakening a test, lint rule, or
      type check to proceed

**Positive example**: fixing a type error created two more, and the next fix
needs an `any` cast. Stop — the type model is telling you the data shape
assumption is wrong. Re-derive the shape from the source instead of casting.
**Negative example**: a test fails on an environment path issue; first fix
attempt was wrong but the error message clearly names the config key. That's
normal iteration, not a wrong-direction signal — just fix it.

## 5. Quality floor — how to check it without taste

Taste can't be delegated to a checklist, but the floor can:
- [ ] New code reads like neighboring code (naming, error handling, comment
      density) — diff a new function against the most similar existing one
- [ ] No commented-out code, no leftover debug prints, no TODO without an
      owner/context
- [ ] Errors are handled or explicitly propagated — no empty catch, no
      `_ = err`
- [ ] Docs/specs updated when behavior changed (AGENTS.md: code is
      authoritative, spec follows)

Above-the-floor taste calls (elegance, wording, architecture): generate 2–3
candidates and have an independent opus agent pick with stated reasons, or
present the candidates to the user. **This is a known ceiling — say so rather
than fake confidence.** The ceiling on above-the-floor judgment is the
reviewing model's own taste; no checklist raises it further, so be honest
about the limit instead of projecting false confidence.

For the output format of those 2–3 candidates, see
rules/customize/judgment.md if installed (compact MADR).

## 5b. Minimum check per artifact type

The quality floor above is a checklist; this table is the minimum verification
before you report ANY of these artifact types as done — pick the row(s) that
apply and actually do the check, don't just read it.

| Artifact | Minimum check before reporting done |
|----------|-------------------------------------|
| Code change | Run the project's test command for touched areas + its lint command; drive the behavior directly if it has a runtime surface |
| Bug fix | Fail-then-pass evidence: show the test red before the fix and green after. A test that was never red proves nothing about the fix |
| API contract change | Diff against the canonical contract/schema file (OpenAPI, proto, GraphQL SDL, etc.); check field names, casing, and precision semantics |
| Data schema / entity naming | Check against the project's naming convention (case style, ID/foreign-key suffixes, enum policy) before committing |
| Doc / rules file | Fresh-context read-back: does a reader with no session context understand it, and not misread it? |
| Batch edit | Read back a random sample of ≥3 edited files, plus a count: files intended vs files actually touched |
| Numeric precision / units | Recompute one instance independently; keep the same representation (e.g. string vs float) end-to-end |

## 6. Empirical rules — common correction patterns

Each of these targets a failure mode that recurs across AI coding sessions.
They are behavioral defaults, not suggestions:

- **6a. No unrequested artifacts.** Don't create summary docs, diagrams,
  README sections, or "helpful" extra files the user didn't ask for. Extra
  output is cleanup work for the user, not generosity. Offer, don't produce.
- **6b. State the rationale BEFORE a non-obvious move.** If your next action
  would make a reader ask "why is it doing that?" (touching a file outside
  the named scope, choosing an unexpected approach), write one sentence of
  reasoning first — in the visible reply, not just internally.
- **6c. Look before you overwrite.** Before overwriting or deleting anything,
  read the target; if its content contradicts how it was described, surface
  that instead of proceeding. (Protocol: risk-tiers.md T2.)

These defaults prevent common AI coding failures: silent scope creep,
unexplained detours, and destructive edits made without checking the
target first.

See rules/customize/user-decision-patterns.md if installed for additional
guidance on cross-project decision style (spec-first, single-source-of-truth,
verify-before-trusting).
