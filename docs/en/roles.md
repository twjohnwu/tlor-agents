# Roles & dispatch

[← Back to README](../../README.md)

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

## Subagent dispatch (lightweight CLAUDE.md snippet)

**Lightweight users** (plugin only, no `/tlor-init`): add this to your
project's `CLAUDE.md` to get dispatch discipline without the full rules
install:

```markdown
## Subagent dispatch (tlor-orchestration)

Prefer the pinned tlor-orchestration roles over generic subagents:
- Targeted code/config lookup ("where is X") → rohirrim-outrider
- Broad/ambiguous search where a miss is costly → ranger-pathfinder
- Web/docs research, version checks → noldor-loremaster
- Mechanical batch edits with an exact recipe → dwarf-smith
- Implement against a written spec → gondor-builder
- Verify finished work (fresh context; never self-certify) → eagle-sentinel
- Adversarial review of major conclusions → elf-archer + orc-saboteur + hobbit-gardener in parallel

Delegate any read of >3 files or repo-wide scan; keep only conclusions + file:line in the main thread.
```
