# judgment.md — customize overlay (candidate comparison + general decisions)

This file is yours: it lives in `rules/customize/`, so the installer never
overwrites it once it exists. It extends the base judgment.md with a
candidate-comparison format and accumulates general (cross-project)
decision records over time.

## Candidate-comparison format (compact MADR)

Whenever you present 2–3 candidates to the user or to a judge agent (base
judgment.md §5's "generate 2–3 candidates" flow, or any "present options
with trade-offs" step), structure the comparison as a compact MADR
(Markdown Any Decision Record):

    ## Decision: <one sentence — what is being decided>

    ### Decision Drivers
    - <criterion for this case, e.g. consistency with neighboring code,
      migration cost, testability>
    - <criterion 2>

    ### Considered Options
    1. <option A in one sentence>
    2. <option B in one sentence>

    ### Pros and Cons
    **Option 1 — <name>**
    - Good: <advantage, tied to a driver>
    - Bad: <disadvantage>

    **Option 2 — <name>**
    - Good: ...
    - Bad: ...

    ### Decision Outcome
    (left blank for the user or judge agent to fill; once filled, state
    the rationale)

Division of labor: MADR is for BEFORE the decision — comparing options.
After the Outcome is filled in, archive per the project's decision-log
convention if one exists (the rejected options become the "initial idea /
why it was wrong" material); if the project has no such convention, the
filled-in MADR document itself is the record. Never maintain the same
decision in full in two places (single source of truth). The archiving
executor is the `/westmarch-scribe` skill, if installed.

## General decisions log

Cross-project decisions archived by `/westmarch-scribe` land here, newest
first. Entry format: `### YYYY-MM-DD — <decision one-liner>`, followed by
the filled compact MADR (or an equivalently complete record). This file
accumulates on your machine and is never overwritten by plugin upgrades.

(no entries yet)
