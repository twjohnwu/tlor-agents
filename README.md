# TLOR Orchestration — a Middle-earth fellowship for Claude Code

[![CI](https://github.com/twjohnwu/tlor-orchestration/actions/workflows/validate.yml/badge.svg)](https://github.com/twjohnwu/tlor-orchestration/actions/workflows/validate.yml)
[![version](https://img.shields.io/badge/version-0.1.1-blue)](https://github.com/twjohnwu/tlor-orchestration/blob/main/.claude-plugin/plugin.json)
[![license](https://img.shields.io/badge/license-MIT-green)](LICENSE)

An orchestration framework for [Claude Code](https://code.claude.com), themed
on Middle-earth. Nine pinned subagent roles with fixed model/effort/tools,
plus dispatch rules, setup skills, and opt-in guard hooks — everything an AI
coding session needs to delegate reliably.

繁體中文說明請見 [README.zh-TW.md](README.zh-TW.md).

## Skills at a glance

### Autoloaded (installed automatically with the plugin/agents)

| Skill | Purpose | When to invoke |
|---|---|---|
| `/rivendell-council` | Convene the adversarial panel (3 lenses, majority-survival verdict) | Irreversible ops, architecture decisions, root-cause verdicts, security judgments |
| `/tlor-init` | Install agents + rules + CLAUDE.md/AGENTS.md routing + optional hooks | First-time setup, or upgrading an existing installation |
| `/tlor-restore` | Rollback to a previous installation from backup | An upgrade needs undoing |
| `/erebor-ledger` | Retrospective token/cost-savings report for tlor role dispatching, split by Fable-5- vs Opus-orchestrator sessions | "usage report", "cost savings report", "token ledger" — not for live in-progress cost estimation |

## Docs

- [Roles & dispatch](docs/en/roles.md) — the worldview, the nine-role fellowship, subagent dispatch snippet
- [Skills](docs/en/skills.md) — full skill detail + the opt-in STDD workflow
- [Rules & hooks](docs/en/rules-and-hooks.md) — the bundled rules files, the two opt-in hooks
- [Installation](docs/en/installation.md) — the two install paths, ownership model, install flags
- [Maintenance](docs/en/maintenance.md) — notes, honest limits, releasing
- [History](docs/en/history.md) — project rename history and the versioning reset
- [Release log](docs/release_log.md) — full version-by-version history (English only)

## License & homage

MIT © [twjohnwu](https://github.com/twjohnwu). A fan homage to
J.R.R. Tolkien's legendarium; not affiliated with or endorsed by the Tolkien
Estate or Middle-earth Enterprises. Race and role names are used
thematically. The rivendell-council convening flow is inspired by, and the
verify-gate hook is adapted from,
[Miguok/fable-harness](https://github.com/Miguok/fable-harness) (MIT).
