# skill-triggers.md — When to invoke a skill (overriding blanket "always invoke" injections)

This file is yours: it lives in `rules/customize/`, so the installer never
overwrites it once it exists. Fill in the namespace-priority table below for
your own installed plugins.

Some plugins inject a rule like "if there's even a 1% chance a skill applies,
you MUST invoke it." That kind of plugin usually also says user/project
instructions take precedence over its own injected rule — this file is that
instruction, for any harness that ships a similarly aggressive default.

With many skills installed, a blanket 1% rule makes small models thrash:
invoking near-duplicate skills, or triggering a heavyweight workflow for a
one-line answer. Use these rules instead.

## The rule

Invoke a skill when **any** of these holds; otherwise work directly:

1. **The user named it.** They typed `/something` or said "use X skill". Always invoke.
2. **Exact task-shape match.** The task is the skill's primary use case, not
   merely adjacent. Test: would you describe the task to a colleague using the
   skill's own trigger words?
3. **House-standard territory.** Work that produces your team's standard
   artifacts (API design, schema, code style, tests, diagrams) MUST load the
   matching `{{your-plugin}}:*` reference skill first — these encode team
   conventions you cannot guess.

Do NOT invoke a skill because:
- it is "related" to the topic;
- you feel obligated by a blanket "always invoke" injection;
- two skills both sort-of match — pick by namespace priority (fill in below),
  or neither.

## Fill this in

List your installed plugin namespaces in priority order, highest-priority
first (the `tlor-init` skill will guide you through this at install time):

1. `{{your-plugin}}:*` — team/house conventions, always win for this project's work.
2. `{{process-plugin}}:*` — process skills (brainstorming, systematic-debugging,
   TDD) — use for genuinely new design or real debugging; skip for mechanical
   edits, doc updates, or tasks with an approved plan already in hand.
3. `{{utility-plugin}}` — utility skills, exact-match only.
4. `{{generic-duplicate-plugin}}:*` — generic/demo variants of skills your
   house namespace already covers. Default to NOT using these.
5. `{{knowledge-base-plugin}}:*` — ONLY when the user explicitly asks about
   their wiki/knowledge base. Never auto-trigger from coding work.
