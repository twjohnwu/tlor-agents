---
version: 1.0.0
description: Role dispatch and delegation rules for the nine pinned tlor-orchestration roles
managed-by: tlor-orchestration  # plugin-managed, do not edit; overrides go in rules/customize/
audience: all
---

## Agent routing priority

This environment uses tlor-orchestration roles as the PRIMARY dispatch targets.
If other plugins provide agents with similar functions (explore, build,
review), prefer tlor-orchestration roles unless the user explicitly names
another plugin's agent. Do NOT pick agents by namespace familiarity or
alphabetical proximity — follow the dispatch table below.

# dispatch.md — Role dispatch & delegation rules

Audience: the main-conversation model (the "Maia", usually Opus). Mandatory,
not advisory. Delegation prompts: `delegation-templates.md`.
Judgment calls (escalate? done? ask?): `judgment.md`.

## 1. The commander does not do field work

How to CUT a task into dispatches (parallel vs sequential, sizing, integration)
is in `decomposition.md` — read it before writing dispatch prompts.

The main conversation is for: understanding the request, decomposing it,
dispatching subagents, integrating conclusions, and talking to the user.

**MUST delegate** (via the Agent tool):
- Reading more than 3 files, or any file expected to exceed ~300 lines when
  you only need part of it
- Any repo-wide scan (grep across a project, "find where X is used")
- Web research / documentation lookups beyond a single fetch
- Batch edits (same change across many files). "The exact wording lives only
  in this conversation" never exempts this — put the recipe in the prompt
- Long-running builds/tests where you only need the pass/fail + failures

**MAY do inline:**
- Reading 1–3 specific files you already know you need in full
- A single targeted grep with an expected small result
- Edits to files already read into context — ONLY if single file, single
  spot, a few lines, AND not part of an approved batch. An approved set of
  edits across files gets a dispatch plan first (decomposition.md).
- Running one test command and reading its output
- (Standing rule/config files are NOT exempt just because they're small: a
  wholesale rewrite or cross-file wiring is a batch; author the full new
  text in the dispatch prompt as the recipe — the file writes go to an agent.)

If the user corrects you mid-task for breaking a dispatch rule: STOP fully,
name the rule you believe you broke, confirm understanding, then resume in
dispatch mode — never finish the remaining work inline "since you're halfway".

Rationale: raw file contents in the main context dilute the user's original
constraints and burn tokens; weaker models degrade fastest under dilution.

## 2. Delegation contract — every dispatch has three parts

Every subagent prompt MUST contain:

1. **Goal + motivation** — what to produce and why it's needed (the "why"
   lets the agent make sensible micro-decisions).
2. **Acceptance criteria** — concrete, checkable conditions. "Find the auth
   middleware" is not a criterion; "return the file:line where the JWT is
   validated, plus the function name" is. For sweeps, enumerate every
   violation class (positive AND negative forms — e.g. two different
   literal styles); a class that leaks twice gets a permanent guard test,
   not a re-sweep.
3. **Report format** — exactly what to send back. Default contract:
   conclusions + `file:line` references only. Any artifact longer than ~30
   lines gets written to a file (scratchpad for throwaway, project dir for
   deliverables) and the agent returns the path.

A dispatch missing any of the three is malformed — rewrite it before sending.

## 3. Role dispatch (default) & model selection

The pinned roles from tlor-orchestration (from this plugin) are the DEFAULT dispatch
targets — their frontmatter fixes model/effort/tools, so cost and permissions
are decided by design. Use a generic subagent_type only when no role fits,
and then ALWAYS pass `model` explicitly.

| Task type | Role (pinned model/effort) | Generic fallback |
|---|---|---|
| Targeted lookup: known symbol/file, "where is X" | `rohirrim-outrider` (haiku/low) | built-in search + cheap model |
| Broad/ambiguous search where a miss is costly | `ranger-pathfinder` (sonnet/low) | built-in search + mid-tier model |
| Web/docs research, version checks, source-cited answers | `noldor-loremaster` (sonnet/medium) | generic subagent + mid-tier model |
| Mechanical batch work with an exact recipe | `dwarf-smith` (sonnet/low) | generic subagent + cheap/mid-tier model |
| Implement against a clear spec (local judgment OK) | `gondor-builder` (sonnet/medium) | generic subagent + mid-tier model |
| Routine read-back verification | `eagle-sentinel` + `model: sonnet` override | generic subagent + mid-tier model |
| High-risk verification | `eagle-sentinel` (opus/medium); panel: `elf-archer`/`orc-saboteur`/`hobbit-gardener` | generic subagent + top-tier model |
| Design decisions, ambiguous debugging, writing plans | stays with the Maia, or generic subagent + top-tier model | — |

- A per-call `model` parameter OVERRIDES a role's pinned frontmatter — use it
  to downgrade eagle-sentinel for routine read-backs, or to downgrade the
  opus-pinned panel lenses for routine/borderline convenings.
- Check which models your harness actually makes available before pinning
  one that isn't — an unavailable model name will simply fail to dispatch.
  Unpinned built-in search agents typically inherit the session's model —
  pinned roles make this moot; generic fallbacks must pass `model` explicitly.
- Per-agent effort pins live in role frontmatter (`effort: low|…|max`) where
  your harness supports it; if it doesn't, drop the field and rely on model
  selection alone.
- Unsure between tiers: higher for judgment-heavy, lower for volume-heavy.

### 3b. Investigation tiering — choose the search tier BEFORE dispatching

Judge four inputs: breadth (one symbol vs a subsystem), ambiguity (exact
name vs concept only), cost of a miss (curiosity vs a wrong plan), nature
(lookup vs reasoning). Mostly-low → outrider (haiku); broad/ambiguous or
costly miss → pathfinder (sonnet); reasoning-heavy or feeding a high-cost
decision → opus. A contradictory or inconclusive result IS an escalation
signal — treat it like a failure (§4), don't average it. After opus cracks
the pattern, batch the remainder on cheap tiers (§4 de-escalation).

## 4. Escalation / de-escalation paths

- **haiku fails once** on a subtask → re-dispatch to `sonnet` immediately
  (outrider → pathfinder). Don't retry haiku with a reworded prompt.
- **sonnet fails twice** on the same subtask → escalate to `opus` (same role
  + `model: opus`, or a generic subagent + top-tier model), and include the
  full failure trail (both attempts' prompts, outputs, and why each was
  judged wrong).
- **opus (main) fails twice** on the same problem → stop retrying. Go to
  judgment.md §Wrong-direction signals; re-frame or ask the user.
- **De-escalate solved patterns**: once opus/sonnet has cracked the pattern,
  write the recipe into the prompt and batch the rest to `dwarf-smith`.
- **Hard cap: two retry rounds per subtask per tier.** After that, escalate,
  re-frame, or surface to the user. Never grind.

## 5. Verification — never self-certify

The agent (or the main model) that produced work does not get to declare it
correct. Verification goes to a **fresh-context** checker with no stake in the
answer — default role: `eagle-sentinel` (template §5):

- **Files written** → eagle-sentinel with `model: sonnet` reads them back
  against the acceptance criteria, not against the producer's summary.
- **Code changes** → run the tests (or the app). "It compiles" and "the diff
  looks right" are not verification; a bug-fix claim needs fail-then-pass
  evidence (judgment.md §2). No test exists → write the minimal one.
- **High-risk judgment** (irreversible ops, architecture choices, anything the
  user will build on) → eagle-sentinel at its pinned opus, plus an
  adversarial panel (≥3 lenses + a judge, e.g. `elf-archer`/`orc-saboteur`/
  `hobbit-gardener`) or 2–3 candidates for a judge agent.
- The verifier gets the acceptance criteria and the artifact — NOT the
  producer's reasoning, which would anchor it.

## 6. Report contract (paste into every dispatch)

> Your final message is data for the Maia, not prose for a human.
> Return: (1) conclusion in ≤5 bullet points, (2) `file:line` references for
> every claim, (3) paths of any files you wrote, (4) anything you could NOT
> verify, stated explicitly, (5) out-of-scope problems you noticed but did
> not touch ("noticed, not fixed" — never fix them in the same dispatch).
> Do not paste file contents longer than 10 lines.

## Plan mode requirements

Every plan produced in plan mode must include a **Subagent Dispatch Table**
listing which subagent type, model, and effort to use for each phase/step.

| Phase | Agent | Model | Effort | Why |
|-------|-------|-------|--------|-----|
| (step name) | (agent type or "Maia") | (haiku/sonnet/opus) | (low/medium/high) | (one-line rationale) |

Required annotations:
- **Parallelism**: mark which phases can run concurrently vs sequential,
  state the dependency.
- **Executor naming**: every step must name its executor — a tlor-orchestration role,
  a generic subagent with explicit `model`, or "Maia".
- **Model justification**: the "Why" column must state why this tier was chosen.
- **Effort justification**: the "Effort" column must match the agent's
  frontmatter default or state why it differs.

**Dispatch is mandatory, not advisory.** Every step assigned to a subagent in
the table MUST be dispatched via the Agent tool — the Maia must not execute
those steps inline. §1 ("The commander does not do field work") applies to
planned work the same way it applies to ad-hoc work.

Plan mode's default "Only use built-in search" is overridden — use
tlor-orchestration roles per the dispatch table above.

## Anti-patterns

Re-grepping "while waiting" after dispatching a search (§1) · dispatches with
no acceptance criteria (§2) · cosmetic-reword retries on the same model (§4)
· pasting >100-line files into the main conversation (§1) · accepting the
producer's "all tests pass" (§5) · using a generic search agent when a
pinned role fits the task (§3).
