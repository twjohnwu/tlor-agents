# TLOR Agents — a Middle-earth fellowship for Claude Code

Seven pinned subagent roles for [Claude Code](https://code.claude.com), themed
on the races of Middle-earth. Each role fixes its **model / effort / tools**
in frontmatter, so cost and responsibility are decided by design — not by
whatever the orchestrator happens to inherit.

繁體中文說明請見 [README.zh-TW.md](README.zh-TW.md).

## The worldview

- **You (the engineer) are Ilúvatar** — the source of intent.
- **The main Claude session is a Maia** — it interprets your will, convenes
  the fellowship, and dispatches the races. It does not do field work itself.
- **Subagents are the peoples of Middle-earth** — each born with a fixed fate
  (frontmatter): what model it runs on, how hard it thinks, which tools it
  may touch.

## The fellowship

| Role | Race & post | Model / effort | Duty |
|---|---|---|---|
| `rohirrim-outrider` | Rohirrim outrider | haiku / low | Fast, cheap, targeted lookup: "where is X / how does Y work" |
| `ranger-pathfinder` | Ranger of the North | sonnet / low | Broad, thorough read-only sweep when a miss is costly |
| `dwarf-smith` | Dwarven smith | sonnet / low | Fully-specified mechanical work; never improvises |
| `eagle-sentinel` | Great Eagle | opus / medium | Fresh-context adversarial verification; CONFIRMED/REFUTED |
| `elf-archer` | Elven archer | sonnet / medium | Correctness lens: every arrow pins one logical flaw |
| `orc-saboteur` | Orc saboteur | sonnet / medium | Security & failure lens: injection, races, partial failure |
| `hobbit-gardener` | Hobbit gardener | sonnet / medium | Simplicity lens: prunes over-engineering |

The last three form the **adversarial review panel** that `eagle-sentinel`
convenes for high-risk verdicts (≥3 independent lenses + a judge).

## Install

### Option A — as a plugin (recommended)

```
/plugin marketplace add twjohnwu/tlor-agents
/plugin install tlor-agents@tlor
```

Updates: bump happens on our side via the `version` field; refresh with
`/plugin marketplace update tlor`.

### Option B — plain copy

```bash
git clone https://github.com/twjohnwu/tlor-agents.git
cd tlor-agents && ./install.sh          # --dry-run / --force / --uninstall
```

Copies the seven `.md` files into `~/.claude/agents/`. Either way, **open a
new Claude Code session afterwards** — agent definitions are loaded at
session start.

## Notes

- **Serena tools are optional.** The two search roles list
  [Serena](https://github.com/oraios/serena) semantic tools in `tools`; if you
  don't have the plugin, the roles fall back to Grep/Glob (instructions say so).
- **Shadowing the built-in Explore**: since Claude Code v2.1.198 the built-in
  `Explore` agent inherits your session model (capped at Opus) — on an
  expensive session, unpinned explores burn the expensive model. To pin it,
  copy `ranger-pathfinder.md` to `~/.claude/agents/Explore.md` (keep
  `name: Explore`... adjust the frontmatter name accordingly).
- **Hard rules slot**: `eagle-sentinel` treats caller-supplied "Hard Rules"
  (non-negotiable house conventions pasted into its prompt) as auto-FAIL on
  violation. Paste yours when dispatching.
- Model names (`haiku`/`sonnet`/`opus`) follow the Agent tool's accepted
  values; edit the frontmatter if your environment differs.

## License & homage

MIT © [twjohnwu](https://github.com/twjohnwu). A fan homage to
J.R.R. Tolkien's legendarium; not affiliated with or endorsed by the Tolkien
Estate. Race and role names are used thematically.
