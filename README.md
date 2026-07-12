# TLOR Agents — a Middle-earth fellowship for Claude Code

Nine pinned subagent roles for [Claude Code](https://code.claude.com), themed
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
| `noldor-loremaster` | Noldorin loremaster | sonnet / medium | Web/docs research with sources and versions; fact vs inference |
| `dwarf-smith` | Dwarven smith | sonnet / low | Fully-specified mechanical work; never improvises |
| `gondor-builder` | Mason of Gondor | sonnet / medium | Implements a clear spec with local judgment; design stays with the Maia |
| `eagle-sentinel` | Great Eagle | opus / medium | Fresh-context adversarial verification; CONFIRMED/REFUTED |
| `elf-archer` | Elven archer | opus / medium | Correctness lens: every arrow pins one logical flaw |
| `orc-saboteur` | Orc saboteur | opus / medium | Security & failure-mode lens: input validation, races, partial failure |
| `hobbit-gardener` | Hobbit gardener | opus / medium | Simplicity lens: prunes over-engineering |

The last three form the **adversarial review panel**: for high-risk verdicts
`eagle-sentinel` recommends it, and the Maia convenes it (≥3 independent
lenses + a judge). For routine or borderline convenings, pass an explicit
`model: sonnet` downgrade when dispatching the lenses — a per-call override beats the
role's pinned frontmatter.

## Skills

The plugin ships one skill, `/tlor-agents:adversarial-review` — the convening
procedure for the panel: assemble a self-contained review package, dispatch
the three lenses in parallel, resolve by majority-survival verdict, and loop
until dry for critical conclusions. Plugin installs get it automatically;
`install.sh` (Option B) copies it to `~/.claude/skills/`, where it is invoked
as `/adversarial-review`. A 繁體中文 translation copy ships alongside it
(`SKILL.zh-TW.md`).

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

Copies the role `.md` files into `~/.claude/agents/` (and records a
`.tlor-manifest` there so `--uninstall` removes exactly what was installed).
Either way, **open a new Claude Code session afterwards** — agent definitions
are loaded at session start.

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

## Limits (honest notes)

- **"Read-only" is behavioral for Bash-carrying roles.** `eagle-sentinel`,
  `elf-archer`, `orc-saboteur`, `rohirrim-outrider` and `ranger-pathfinder` hold Bash to run tests/inspection; Bash can
  technically write, so their never-edits stance is an instruction, not a sandbox.
  `hobbit-gardener` is the one panel role that is read-only at the tool level.
- **Unavailable model → silent fallback.** Per official docs, a `model:` value
  your org excludes makes the subagent run on the inherited session model
  instead — no error. If you have no opus access, `eagle-sentinel` quietly
  runs on your session's model.
- **Security-lens roles may trip a model's safety filter.** `orc-saboteur`
  (and to a lesser degree `elf-archer`) do adversarial *defensive* review; on
  some models a broad safety classifier may read that as offensive-security
  work and auto-switch models mid-task. It's a known false positive — the
  review still completes. Wording is kept defensive to minimize it.

## Releasing (maintainers)

Before publishing changes: `claude plugin validate . --strict` (validates
plugin.json + agent frontmatter), test locally with
`claude --plugin-dir .`, then bump `version` in `.claude-plugin/plugin.json` —
users only receive updates when the version changes.

## License & homage

MIT © [twjohnwu](https://github.com/twjohnwu). A fan homage to
J.R.R. Tolkien's legendarium; not affiliated with or endorsed by the Tolkien
Estate or Middle-earth Enterprises. Race and role names are used
thematically. The adversarial-review convening flow is inspired by
[Miguok/fable-harness](https://github.com/Miguok/fable-harness) (MIT).
