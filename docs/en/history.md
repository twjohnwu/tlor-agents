# History

[← Back to README](../../README.md)

## Renamed: tlor-agents → tlor-orchestration (2.x → 3.0)

This repo was renamed from `tlor-agents` to `tlor-orchestration`; GitHub
redirects the old URLs automatically, but plugin installs are keyed by repo
name, so a manual step is required:

```
/plugin uninstall tlor-agents@tlor        # remove the old install
/plugin marketplace add twjohnwu/tlor-orchestration
/plugin install tlor-orchestration@tlor   # re-add under the new name
```

If you installed via `install.sh` (plain copy), just re-run the new
`install.sh` — see the ownership model in [installation.md](installation.md)
for what changes on upgrade.

**v3.0.0 also changes the install/ownership model** (see
[installation.md](installation.md)): base rule files are now plugin-owned
and overwritten unconditionally on every install; anything you want to keep
across upgrades belongs in `rules/customize/`, which the installer never
touches. If you had hand-edited a base rule file in place under 2.x, move
your edits into `rules/customize/` before upgrading — the next install will
overwrite the base file with the shipped version.

## Versioning reset (3.0.0 → 0.0.1)

This project has evolved through three architecture stages: (1) agents role
base (1.x — nine pinned role definitions), (2) rule-assigned agents (2.x–3.0
— roles wired to institution dispatch rules), (3) orchestration (0.x — a
full orchestration framework; process pipelines such as STDD will be
integrated). The repositioning restarts versioning at 0.0.1.

Machines with 2.x/3.x installed will NOT receive the lower version via
`/plugin marketplace update` (version downgrades are ignored per Claude
Code's plugin version resolution). To migrate: uninstall the plugin, remove
the marketplace, re-add the marketplace, then reinstall.

For the full version-by-version log (including everything before and after
this repositioning), see [release_log.md](../release_log.md).
