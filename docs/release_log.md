# Release log

[← Back to README](../README.md)

English only — this file has no zh-TW mirror. Reconstructed from
`git log --oneline` and `AGENTS.local.md`'s version/incident records. Newest
release first — new sections go at the top.

## v0.1.5 — 2026-07-21

- `/tlor-init` Step 5 now offers the `rules/customize/judgment.md` seed
  during install (functional omission from v0.1.3 — the installer skill
  never asked about it).
- Docs catch-up for v0.1.3: rules-and-hooks (en/zh-TW) optional table
  lists the judgment.md seed (6 files, was 5); both READMEs' autoloaded
  skills table gains the `/westmarch-scribe` row.
- README version badges switched from a hardcoded static badge (stuck at
  0.1.2) to a shields.io dynamic JSON badge reading plugin.json's version.
- erebor-ledger SKILL.md: added a closing "Before you report" checklist
  (every requested month rendered; comparison table present in `--month`
  multi-month mode) and a cross-month comparison example table.

## v0.1.4 — 2026-07-21

- erebor-ledger: `--detail-others` flag breaks the merged `(other
  subagents)` row into one row per distinct non-tlor-role `agentType`
  (built-in Explore, `general-purpose`, plugin agents, ...), sorted by
  descending money saved (unpriced rows last).
- erebor-ledger: per-role tables gain `Model`/`Effort` columns; rows are now
  keyed by `(role, model, effort)`, so a role dispatched with a per-call
  model/effort override (rules/dispatch.md §3/§4) shows as its own row
  adjacent to that role's other rows. `Model` is the shortened
  `.message.model` id, suffixed with `(upgrade)`/`(downgrade)` when the
  row's actual model family/tier differs from the role's pinned
  frontmatter `model:` (same family regardless of version, no pin, or an
  unrecognized family never gets a marker); `Effort` is a recorded
  per-dispatch value if one exists, else the role's pinned frontmatter
  marked `*`, else `—` — a new report-header disclosure explains the `*`
  marker and the model-pin comparison behind the `(upgrade)`/`(downgrade)`
  marker.

## v0.1.3 — 2026-07-21

- erebor-ledger: new `--until YYYY-MM-DD` upper bound and repeatable
  `--month YYYY-MM` (single-month reports and multi-month comparison in ONE
  script run; `--month` is mutually exclusive with `--since`/`--until`).
- New customize seed `rules/customize/judgment.md`: compact-MADR
  candidate-comparison format + general decisions log (copy-if-absent,
  never overwritten on upgrade). Base judgment.md §5 gains a one-line
  conditional pointer.
- New skill `westmarch-scribe` (decision capture): archives a filled MADR
  to the project decision log / instruction file / general decisions log,
  AskUserQuestion-driven. Advisory closing hook added to
  stdd-explore / stdd-uiux / stdd-spec / stdd-plan.

## v0.1.2 — 2026-07-20

Skill-body refinements from the first skill-creator evaluation round
(18 scenario runs + adversarial grading, 71/72 assertions passed):

- `stdd-execute`: RED phase now explicitly covers the import-error trap —
  build a minimal `NotImplementedError` stub first so the failure is
  behavioral, not an import error.
- `erebor-ledger`: run the script once per report and quote that single
  run's output verbatim; live transcripts grow between runs, so re-running
  or hand-recomputing numbers makes the prose disagree with its own quoted
  evidence.
- `stdd-spec`: the conditional C1/C2 diagram lives in its own document
  section (e.g. `## System context`), not as an `S-XX` scenario — a diagram
  is not a testable behavior and would pollute coverage math.
- `stdd` (dashboard): pinned the canonical `N/M` progress denominator to
  ALL tasks (scenario + `[INFRA]`); scenario-only counts are secondary,
  clearly labeled.
- `tlor-init` / `tlor-restore`: added the missing `name:` frontmatter field
  (skill-triggering reliability).

## v0.1.1 — 2026-07-19 (7824419)

Old-name (`tlor-agents`) residue cleanup, marketplace description sync, and
this README split into a `docs/` tree (this file included) to keep both
root READMEs short.

## v0.1.0 — 2026-07-19 (`b19d948`)

Added the seven opt-in STDD (Spec-driven Test-Driven Development) workflow
skills (`stdd`, `stdd-explore`, `stdd-uiux`, `stdd-spec`, `stdd-plan`,
`stdd-execute`, `stdd-lint`), the `erebor-ledger` retrospective cost-savings
skill, and the install/hook layer (`--stdd-role`, `--install-hook`).

## v0.0.1 — 2026-07-19 (`e078b74`)

Version reset for orchestration-stage repositioning. The project's
architecture is framed as three evolution stages: (1) agents role base
(1.x — nine pinned role definitions), (2) rule-assigned agents (2.x–3.0 —
roles wired to institution dispatch rules), (3) orchestration (0.x — full
orchestration framework, with process pipelines such as STDD to be
integrated). Versioning restarts at 0.0.1 to reflect stage (3). See
[history.md](en/history.md) / [zh-TW 版](zh-TW/history.md) for the
user-facing explanation and migration note.

## v3.0.0 (never released) — 2026-07-16 to 2026-07-17 (`644cff9`, `a621278`, `f1a049d`)

Repo renamed `tlor-agents` → `tlor-orchestration`; new institution &
ownership model (base rules plugin-owned and unconditionally overwritten,
`rules/customize/` user-owned and never touched). Follow-up commits made the
base layer zero-user-writable (moved `skill-triggers.md` to `customize/`)
and dropped the shipped version placeholder from base rules, making the
installer the sole version source. This version line was superseded by the
0.0.1 reset below before a `3.0.0` tag/release went out.

## v2.1.0 — 2026-07-14 (`fffdeea`)

Added `rules/customize/` for optional rules, generated CLAUDE.md+AGENTS.md
routing, and dispatch-table improvements.

## v2.0 — 2026-07-14 (`39e96d3`, docs in `15e63c3`)

Orchestration framework: added the rules directory (dispatch, decomposition,
delegation-templates, judgment, risk-tiers, maintenance), skills, and hooks
as a bundled install target, with matching README sections.

## v1.4.0 — 2026-07-12 (`81159e4`, plus `5cf0ff2`)

Skill renamed `adversarial-review` → `rivendell-council` (Council-of-Elrond
imagery; description keeps all trigger words). Added Triggering guidance and
a copy-paste CLAUDE.md line to both READMEs. New opt-in `verify_gate` Stop
hook (silent unless `TLOR_VERIFY_GATE=1`) — a substantial derivation from
Miguok/fable-harness's `verify_gate.py`, credited via MIT copyright notice in
the file header. `eagle-sentinel` gained fail-then-pass wording;
`gondor-builder` gained a noticed-not-fixed line. Same-day follow-up
(`5cf0ff2`) added GitHub Actions CI (`validate.yml`) and the three README
badges (CI status, version, license).

## v1.3.0 — 2026-07-12 (`870cba0`)

Shipped the adversarial-review convening skill
(`skills/adversarial-review/`, English canonical + zh-TW translation).
`install.sh` now installs skills via the manifest, making the panel-convening
procedure executable.

## v1.2.0 — 2026-07-11 (`9f97f13`)

Fourth role review: `noldor-loremaster` gained scratch-only `Write`;
read-only-Bash disclaimers added to `rohirrim-outrider`/`ranger-pathfinder`;
panel lenses (`elf-archer`/`orc-saboteur`/`hobbit-gardener`) re-pinned from
sonnet to opus, with a documented per-call sonnet downgrade for routine
convenings. Merging outrider+pathfinder into one role was considered and
rejected — pin-by-design is the product thesis.

## v1.1.3 — 2026-07-11 (`734a1af`)

Contention re-audit (repo sweep + IP research): both READMEs now name
Middle-earth Enterprises alongside the Tolkien Estate in the disclaimer.
"TLOR" deliberately kept unexpanded; no other legal-boilerplate changes made.

## v1.1.2 — 2026-07-11 (`8eacf46`)

Reframed `orc-saboteur` (and lightly `elf-archer`) from attacker-persona
wording ("attack", "besieger", "self-escalation", `attack_findings`) to
defensive/failure-mode wording after a safety-filter false positive
auto-switched a review session to a different model mid-task. Function
unchanged; only the framing changed.

## v1.1.1 — 2026-07-11 (`7382a33`)

Added a common "Evidence rule" across all 9 roles after a `dwarf-smith`
dispatch volunteered an unsourced, evidence-free out-of-scope claim (likely
from reading a stale `*.bak-*` sibling file). Claims now require file:line
from a file read that dispatch; backups aren't evidence. Hardened
`dwarf-smith`'s noticed-not-fixed list and gave `eagle-sentinel` ownership of
panel synthesis back to the Maia.

## v1.1.0 — 2026-07-11 (`54883f3`)

Added `gondor-builder` and `noldor-loremaster`, bringing the roster to nine
roles. Added a `dwarf-smith` scope gate, reworded `eagle-sentinel`'s panel
wording, added `install.sh` manifest tracking and install guards, and got a
clean `claude plugin validate . --strict` pass.

## v1.0.0 — 2026-07-11 (`0b2c8cf`)

TLOR Agents initial release: seven Middle-earth-themed pinned subagent roles
(rohirrim-outrider, ranger-pathfinder, dwarf-smith, eagle-sentinel,
elf-archer, orc-saboteur, hobbit-gardener), each with fixed model/effort/tools.
