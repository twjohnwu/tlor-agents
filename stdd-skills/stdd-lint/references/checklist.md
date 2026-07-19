# Reference: the 8 mechanical checks, at a glance

Tabulates the 8 checks `stdd-lint` runs, per `STDD/specs/stdd-lint.md`. See
`SKILL.md` for the full behavior of each check; this page is a
quick-reference table only.

| Check | S-ID | Triggers when | FAILs when |
|---|---|---|---|
| Placeholder text scan (incl. `prototype/` leakage) | S-26 | `spec.md` or `tasks.md` exists | any `TBD`/`TODO`/vague filler/dangling reference found; OR a `prototype/` path reference leaks into a task's named file or a git-changed file; OR (non-git project + `tasks.md` names no concrete files) scan scope can't be determined |
| Scenario ID continuity and uniqueness | S-27 | a change's `spec.md` exists | any `S-XX` ID appears more than once (gaps are reported, not judged) |
| GWT + Test mapping / Verification command completeness | S-28 | `spec.md` exists | any scenario is missing GIVEN, WHEN, THEN, `Test mapping`, or `Verification command` |
| Coverage comparison | S-29 | `spec.md` AND `tasks.md` exist | either the manual or automatable track is below 100% coverage against `tasks.md` (`[INFRA]`/`prototype/` excluded from the denominator) |
| Two-file fingerprint comparison (+ design-ux consistency) | S-30 | `spec.md`'s frontmatter carries `approved_fingerprint` | recomputed `spec.md` body fingerprint disagrees with `approved_fingerprint`; OR recomputed `design-ux.md` body fingerprint disagrees with `design_ux_fingerprint`; OR the design-ux consistency check's (a)/(b) branches fire (fingerprint non-null but file missing, or fingerprint null but file exists) — see the v2→v3 migration note below |
| INFRA/MANUAL reason lines + D5 deferred-ratio stats | S-40 | `tasks.md` exists | any `[INFRA]`/`[MANUAL]` task is missing its one-line reason (the D5 deferred-ratio number itself has no ceiling and never fails on its own — it's reported for human review) |
| Not-installed STOP rule | S-31 | a caller (`stdd-spec`/`stdd-plan`/`stdd-execute`) needs `/stdd-lint` and it isn't installed | this rule governs the CALLER, not `stdd-lint` itself — the caller must STOP and report, never silently skip |
| Banned Mermaid construct scan | S-53 | any change artifact (`spec.md`, `design-be.md`, `design-fe.md`, `design-ux.md`, etc.) contains a Mermaid code block | any block uses a construct listed in "Banned Mermaid constructs" below |

## Banned Mermaid constructs (single source of truth — R7-1)

- **Experimental C4 syntax** (`C4Context`, `C4Container`, etc.) — GitHub's
  native Mermaid renderer doesn't support it.
- **Gantt charts** — AI-generated task effort has no reliable timeline to plot.

**Maintenance note**: any future similar ban lands HERE, in this section —
this is the single source; `stdd-*` templates and skills SHALL NOT restate
this list, only reference it.

**Lint scan rule**: `/stdd-lint` scans every Mermaid code block in a change's
artifacts (`spec.md`, `design-be.md`, `design-fe.md`, `design-ux.md`, etc.)
against this list; any match is reported as **FAIL** with the offending
`file:line`.

## v2→v3 migration note (extends the fingerprint-comparison row above)

Per `STDD/specs/stdd-integration.md` S-36 (referenced here, not restated):
before comparing fingerprints, distinguish two cases for
`design_ux_fingerprint` in `spec.md`'s frontmatter —

- **Key entirely absent** (not merely `null`) → this is a v2-era artifact
  that predates the two-file fingerprint scheme. Treat it as `draft`
  regardless of its recorded `status`, and require a one-time re-approval —
  never pass silently.
- **Key present and set to `null`** → legal v3 state (no UI surface); do not
  treat this as a migration case.

The distinction matters because a v2 spec's fingerprint check would
otherwise be skipped entirely (no key to compare) and silently pass — the
migration case exists specifically to prevent that silent pass.
