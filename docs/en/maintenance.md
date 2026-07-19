# Maintenance

[← Back to README](../../README.md)

## Notes

- **CLAUDE.md + AGENTS.md architecture.** `/tlor-init` generates a thin
  `CLAUDE.md` (with an `@AGENTS.md` import) plus an `AGENTS.md` carrying the
  routing table. AGENTS.md is also readable by other AI coding tools
  (Cursor, Codex, etc.), so the routing table isn't locked to Claude Code.
- **Serena tools are optional.** The two search roles list
  [Serena](https://github.com/oraios/serena) semantic tools in `tools`; if you
  don't have the plugin, the roles fall back to Grep/Glob (instructions say so).
- **Hard rules slot**: `eagle-sentinel` treats caller-supplied "Hard Rules"
  (non-negotiable house conventions pasted into its prompt) as auto-FAIL on
  violation. Paste yours when dispatching.
- Model names (`haiku`/`sonnet`/`opus`) follow the Agent tool's accepted
  values; edit the frontmatter if your environment differs. The rules use
  tier-based language (cheap/mid-tier/top-tier) so they stay portable even as
  agent frontmatter keeps specific model names.

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

Full version-by-version history: [release_log.md](../release_log.md). Future
releases append there.
