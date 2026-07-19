# GWT and RFC 2119 — distilled reference

Bundled reference for `stdd-spec`. Covers scenario quality rules, the
frontmatter contract, and mistakes to avoid — not a general GWT tutorial.

## GWT quality rules

- **GIVEN** describes the starting state, not an action. Prefer "a delivery
  has reached `attempt == 5`" over "the worker retries 5 times" (that's a
  WHEN, not a GIVEN).
- **WHEN** is exactly one triggering event. If a scenario needs "and then"
  between two WHENs, it is probably two scenarios.
- **THEN** is observable and checkable — state a concrete assertion
  ("status SHALL be `failed`"), not an intention ("should handle the error
  well").
- One scenario = one `S-XX` ID. Don't fold multiple THENs covering unrelated
  behavior into a single scenario just to save an ID.
- Every scenario carries a `Test mapping` (the expected test file/function)
  and a `Verification command` (a command that can actually be run) — a
  scenario missing either is incomplete per `stdd-lint` S-28.

## RFC 2119 keyword usage

| Keyword | Use for |
|---|---|
| `SHALL` / `MUST` | A hard requirement — no exceptions, no room for "it depends" |
| `SHALL NOT` / `MUST NOT` | A hard prohibition |
| `SHOULD` | A recommendation that can be overridden with a stated reason |
| `SHOULD NOT` | Discouraged, with room for a stated exception |
| `MAY` | Truly optional; the requirement doesn't rely on this happening |

Prefer `SHALL`/`SHALL NOT` for anything a `Verification command` will check
mechanically — `SHOULD` reads as advisory and doesn't belong in a scenario
whose pass/fail a test asserts.

## Common mistakes

- **Vague THEN**: "the system SHALL handle errors gracefully" — not
  checkable. Rewrite: name the exact status/field/response the test asserts.
- **Missing `Verification command`**: a scenario with `Test mapping: manual`
  still needs a `Verification command` describing the manual steps, not a
  blank field.
- **GWT masquerading as a checklist**: don't cram unrelated assertions into
  one THEN just to avoid minting a new `S-XX` — split them.
- **Banned Mermaid constructs**: use plain `graph`/`flowchart` for C1/C2 (and
  C3 in `stdd-plan`) instead — see `templates/spec.md` for a worked example.
  Single source of truth for the banned-constructs list is `stdd-lint`'s
  `references/checklist.md` — not restated here.
