---
name: erebor-ledger
description: 'Token/cost-savings ledger for tlor-agents dispatching — reports how much dispatching to tlor roles saved versus running the same work inline on the orchestrator model, split by Fable-5-orchestrator sessions vs Opus-orchestrator sessions. Triggers: "usage report", "cost savings report", "token ledger", "省了多少 token/成本", "how much token/cost saved", "dispatch savings". Not for live cost estimation of a single in-progress dispatch — this is a retrospective report over existing Claude Code transcripts.'
---

# Erebor Ledger (寶庫清點 — dispatch token/cost savings report)

> Named for the dwarves' vaults under the Lonely Mountain, where every coin
> is counted. This skill counts not gold but tokens: how much a dispatch to
> a tlor role actually cost, versus what it would have cost the
> orchestrator to do the same work inline.

## Purpose

Answers two independent questions, never merged:

1. When **Fable 5** is the orchestrator (main-session model), how much did
   dispatching to tlor-agents save versus doing the work inline?
2. When **any Opus version** (excluding Fable 5) is the orchestrator, what's
   the same answer?

Fable 5 and Opus have different unit prices and token-consumption patterns
— averaging them across groups would distort the savings estimate, so each
group gets its own report and its own totals.

## Data sources

Reads Claude Code transcript JSONL directly — no external API, no network
call:

- **Main-session transcript**: `~/.claude/projects/<proj>/<sessionId>.jsonl`
- **Subagent transcripts**: `<sessionId>/subagents/agent-<agentId>.jsonl` +
  `agent-<agentId>.meta.json` (the `agentType` field maps a subagent
  transcript back to the role name it was dispatched as)
- Per assistant record: `.message.model` and
  `.message.usage.{input_tokens,output_tokens,cache_creation_input_tokens,
  cache_read_input_tokens}`
- `.message.model == "<synthetic>"` records are excluded from every total —
  they are never billed and never counted

These are internal Claude Code transcript fields, not a documented public
API — a CC version upgrade may rename or restructure them. If the fields
this skill reads don't match what's installed, `erebor_ledger.py` will
either error out or produce visibly empty reports rather than silently
guessing at a different schema; investigate and fix the field paths before
trusting a "clean" run.

## How to run it

```bash
python3 skills/erebor-ledger/scripts/erebor_ledger.py [--project SUBSTR] [--since YYYY-MM-DD]
```

- No flags: scans every project under `~/.claude/projects/` and its full
  history.
- `--project <substring>`: only includes project directories whose name
  contains this substring.
- `--since YYYY-MM-DD`: only includes records at or after this date, using
  the transcript's own `timestamp` field. (`--root` also exists as an
  advanced/testing override of the transcripts root directory — not part
  of the two documented filters above, useful for running against a fixture
  directory instead of the real `~/.claude/projects/`.)

Python 3 standard library only — no `pip install` required.

## Savings methodology

- **Actual cost** = Σ(each subagent assistant record's tokens × that
  record's own `.message.model` price)
- **Counterfactual cost** = the same token totals × the session's
  orchestrator-model price (i.e. "what if the orchestrator had done this
  work inline instead")
- **Saved** = counterfactual cost − actual cost
- input / output / cache_read / cache_write tokens are priced **separately**
  and summed — never a single blended rate

Every report **SHALL** carry this disclosure, verbatim or in equivalent
wording:

> Counterfactual assumes inline execution would consume the same token
> volume; this is an estimate, not a measurement.

It also discloses a pricing-tier assumption: Claude Code transcripts don't
record whether a cache write used the 5-minute or 1-hour cache tier, so
every cache-write cost in this report is priced at the 5-minute tier. This
is stated in the report output every run — never omit it.

## Per-role table (mandatory format — do not invent a different one)

Every group (Fable / Opus) gets its own per-role table with this exact
column set and order — this is the implementation contract, not a
suggestion:

| Role | Dispatches | input | output | cache(r/w) | Actual cost | Counterfactual cost | money saved | saved % |
|---|---|---|---|---|---|---|---|---|

The nine tlor roles (`rohirrim-outrider`, `ranger-pathfinder`,
`noldor-loremaster`, `dwarf-smith`, `gondor-builder`, `eagle-sentinel`,
`elf-archer`, `orc-saboteur`, `hobbit-gardener`) each get their own row when
they appear in the data; anything else (built-in Explore, a generic
subagent) is merged into a single `(other subagents)` row. The last row is
always **Total saved**.

### Example (illustrative numbers — the format is the contract, the numbers are not)

Fable group per-role example:

| Role | Dispatches | input | output | cache(r/w) | Actual cost | Counterfactual cost | money saved | saved % |
|---|---|---|---|---|---|---|---|---|
| rohirrim-outrider | 12 | 8,400 | 2,100 | 15,000/3,200 | $0.42 | $3.10 | $2.68 | 86.5% |
| ranger-pathfinder | 5 | 6,000 | 4,500 | 9,800/1,500 | $0.61 | $2.95 | $2.34 | 79.3% |
| noldor-loremaster | 2 | 3,200 | 1,800 | 2,000/500 | $0.28 | $1.10 | $0.82 | 74.5% |
| dwarf-smith | 3 | 4,100 | 3,000 | 5,600/900 | $0.35 | $1.85 | $1.50 | 81.1% |
| gondor-builder | 4 | 9,000 | 6,200 | 12,000/2,100 | $0.90 | $4.20 | $3.30 | 78.6% |
| eagle-sentinel | 6 | 7,500 | 3,900 | 8,000/1,200 | $0.55 | $2.80 | $2.25 | 80.4% |
| elf-archer | 1 | 1,200 | 900 | 600/100 | $0.10 | $0.55 | $0.45 | 81.8% |
| orc-saboteur | 1 | 1,300 | 950 | 700/100 | $0.11 | $0.58 | $0.47 | 81.0% |
| hobbit-gardener | 1 | 1,100 | 800 | 500/100 | $0.09 | $0.50 | $0.41 | 82.0% |
| (other subagents) | 2 | 2,000 | 1,000 | 1,000/200 | $0.15 | $0.70 | $0.55 | 78.6% |
| **Total saved** | **37** | — | — | — | **$3.56** | **$18.33** | **$14.77** | **80.6%** |

The Opus group's structure mirrors the table above exactly (same column
order); its numbers are computed separately and not duplicated here.

Each group report also carries:

- **Group summary**: session count, orchestrator's cumulative tokens/cost for
  that group, and the group's Total saved
- **Per-project subtotal**: saved amount split out by `<proj>` directory

If a `.message.model` has no matching price entry (see below), its row's
cost cells print `N/A` instead of a dollar figure — never a `$0.00` that
could be misread as "no savings", and never a guessed number.

## Pricing (`references/model-prices.json`)

Config-driven, not hardcoded in the script. Matching is **longest-prefix
match**: a price-table key matches a `.message.model` id if the model id
*starts with* that key (e.g. a hypothetical `claude-opus-4-6` model would
match a `claude-opus-4` price-table entry, not require an exact match).

- Model id with no matching prefix → tokens are still listed normally, the
  cost column shows `N/A`, and the script prints a warning naming the
  unpriced model id. The script **never** substitutes another model's price
  for an unknown one.
- If a `claude-fable-5*` variant has no public pricing, its JSON entry uses
  `null` — a human SHALL fill in the real number (measured or officially
  announced) before that entry can price anything.
- Cache-write prices are quoted at the 5-minute cache tier only (see
  disclosure above) — if Anthropic's pricing model changes this, update
  `model-prices.json`, not the script.
- To add/repair a price, edit `references/model-prices.json` directly; do
  not hardcode prices in `erebor_ledger.py`.

## Non-goals

- Does not estimate the cost of a dispatch that hasn't happened yet.
- Does not write, delete, or modify any transcript or config file — read-only.
- Does not call any network API; all pricing comes from the local
  `model-prices.json`, refreshed by hand when Anthropic's pricing page changes.
