---
name: westmarch-scribe
description: 'Use when a decision just got finalized or reversed in conversation and needs to be archived — the user says "就這樣定了", "決定用 X", "把這個決策存起來", "記錄這個決策", "archive this decision", "record this decision", "we''ve decided", explicit `/westmarch-scribe`, or a stdd phase skill''s closing advisory suggests archiving. Archives a DECIDED compact-MADR comparison (Decision / Decision Drivers / Considered Options / Pros and Cons / Decision Outcome) to the right durable location — the rules customize layer for a cross-project decision, or a project decision log / instruction file for a project-scoped one.'
---

# Westmarch Scribe (西境紅皮書執筆者)

> Named for the scribes who kept the Red Book of Westmarch — they wrote
> down what was decided, not what was debated. This skill only touches a
> comparison once its Decision Outcome is filled in; an argument still in
> progress has nothing yet for the scribe to record.

This skill now retriggers proactively on the keywords in its description
above, rather than waiting solely for explicit invocation — the
`AskUserQuestion` forks throughout (Steps 1, 3, and 4) are what keep that
proactivity safe, since every ambiguous or irreversible branch still stops
for an explicit, closed-option confirmation before anything is written.

## Purpose

Takes a compact-MADR (Markdown Architecture Decision Record) document that
has already reached a decided outcome, and files it durably in the right
place — either this machine's rules customize layer (cross-project
decisions) or the deciding project's own decision log or instruction file
(project-scoped decisions). It never invents the archiving location by
guessing; every ambiguous branch below is resolved by an `AskUserQuestion`
with explicit options, never an open-ended prompt.

## Step 0 — Gate: tlor rules installed?

Resolve the installed rules directory (portable wording: `~/.claude/rules`,
`.claude/rules`, or wherever this environment's rules layer actually lives —
whether that's a symlink or a real directory; adapt to the installed
layout). Confirm the base rule files `dispatch.md` and `judgment.md` exist
there.

If either is missing: **STOP**. Report exactly: "tlor rules not installed —
run `/tlor-init` first". Do not silently continue — there is no durable
location to archive into without the rules layer, and guessing one would
misfile the record.

## Step 1 — Collect input

Needs a compact-MADR document (file path, or pasted directly in
conversation) containing all of:

- `## Decision`
- `### Decision Drivers`
- `### Considered Options`
- `### Pros and Cons`
- `### Decision Outcome`

Plus metadata: **date**, **repo** (or "cross-project" if none), **feature**,
**decision-maker**.

If any metadata field is missing, ask for all of them in **one batched**
`AskUserQuestion` — never drip individual questions across turns.

**Decision-maker MUST NOT default to the current operator.** Decisions
often come from someone else — a PM, a client, another team — and assuming
the person running this skill is also the decision-maker silently
misattributes the record. Offer explicit options:

- the current operator
- someone else (an "Other" free-text option for a name)

Never skip this choice by inferring it from who is present in the
conversation.

## Step 2 — Gate: is this actually decided?

Verify all five MADR sections are present **and** `### Decision Outcome` is
filled in (not empty, not a placeholder like "TBD").

If Decision Outcome is empty: **STOP**. Tell the user the decision hasn't
been made yet — an undecided comparison is not something to archive. Do not
proceed to Step 3 or write anything.

## Step 3 — Durability test

Before writing anything, the decision must satisfy at least one of:

1. Changes a contract/schema/architecture/convention with future
   consequences.
2. Encodes a non-obvious transferable lesson.
3. Guards against a plausible future re-litigation of the same argument.

If none apply: recommend **not** archiving and explain why in plain terms —
an honest no-op is a valid deliverable here, not a failure to produce
something. Then ask via `AskUserQuestion` with explicit options:

- archive anyway
- skip (don't archive)

Only proceed past this point if the user picked "archive anyway" or the
durability test passed outright.

## Step 4 — Scope routing

If it's unclear whether this is a general or project-scoped decision, ask
via `AskUserQuestion` with explicit options: **general (cross-project)** /
**project-scoped**.

### 4a. General (cross-project) decision

If the rules customize layer has no `judgment.md` yet, create it first,
following the plugin seed's structure (`rules/customize/judgment.md` in this
plugin bundle) as the shape to copy:

- a header noting the file is user-owned and never overwritten by the
  installer;
- the compact-MADR candidate-comparison format section;
- a "General decisions log" section.

Only after the file exists (newly created or already present), append to its
"General decisions log" section (portable wording — on this machine that's
e.g. `~/.claude/rules/customize/judgment.md`; adapt the path to wherever the
installed rules customize layer actually lives). Entry format:

```
### YYYY-MM-DD — <one-liner>

<the filled MADR, verbatim>
```

### 4b. Project decision

Detect whether the repo already has a decision log — common shapes:
`docs/decisions_log.md`, `decisions_log/<repo>.md`, an ADR directory
(e.g. `docs/adr/`, `docs/decisions/`).

- **Exists** → append one entry following that log's **own existing
  convention** — its language and its format. For example, if the log uses
  a four-part 最初想法 / 為什麼錯 / 現在做法 / 學到什麼 structure, map the
  MADR's rejected options into the first two parts, not the other way
  around. Never impose the MADR shape onto a log that already has its own —
  the destination format wins.
- **Missing** → `AskUserQuestion`: create a decision log for this repo?
  - **Yes** → **first time only**, `AskUserQuestion` for the log's
    language (e.g. 繁體中文 / English). Create the file and record the
    chosen language in the file's header. Every later run for this repo
    **follows the file's existing language** — never ask again once a log
    exists.
  - **No** → write the decision as one compact line into whichever
    instruction file the environment already uses (`CLAUDE.md` /
    `AGENTS.md` / `CLAUDE.local.md` / `AGENTS.local.md` — the `.local`
    variants are personal-layer and not committed). Also record, in the
    same file, the standing preference "this repo keeps decisions in its
    instruction file, no decision log" — so future runs never re-ask
    whether to create one.

## Step 5 — Commit

In a git-tracked project, commit the single touched project file, with a
commit message containing the decision's one-liner. This is reversible and
needs no ceremony beyond the normal commit-hygiene rules already in force.

**Never commit** the rules customize-layer file (Step 4a) or any `.local`
file (Step 4b "No" branch) — those are personal/machine-layer, not part of
the project's git history.

## Rule: every question is a closed question

Every question or suggestion this skill raises with the user goes through
`AskUserQuestion` with explicit, enumerated options — never an open-ended
"what would you like to do?" prompt. This applies to every branch above:
missing metadata, the durability-test fork, the scope-routing fork, the
create-a-log fork, and the log-language question.

## Non-goals

- Does not decide FOR the user whether something is decided, durable, or
  which scope it belongs to beyond what's stated above — every fork is an
  explicit question, not an inference.
- Does not implement automatic invocation from stdd phase-skill closing
  advisories; those hooks live in the stdd skills themselves, not here.
- Does not hardcode any company- or project-specific integration (no
  external wiki/spec-hub ingestion) — those are per-machine extensions a
  user can add on top, not part of this skill.
- Creates or edits nothing beyond this single file's own logic — no
  scripts, no helper files.
