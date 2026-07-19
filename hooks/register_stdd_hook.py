# -*- coding: utf-8 -*-
"""
register_stdd_hook.py — idempotently add the STDD test-file guard's
PreToolUse entry to a Claude Code settings.json.

Usage: python3 register_stdd_hook.py <settings.json path> <hook script path>

Creates settings.json (and its parent dir) if missing. Never removes any
existing hook entries; only appends this one if an entry with the exact
same command isn't already present. Exits non-zero with a message on
malformed existing JSON — never guesses and overwrites a file it can't
parse.

The registered entry is scoped with `"matcher": "Write|Edit|NotebookEdit"`
(matching the exact tool set stdd_test_guard.py's own tool_name check
covers) so it only fires on file-writing tool calls, not every tool
invocation. Idempotency detection still matches on the `command` string
alone (not the matcher), so a re-run against an entry registered before
this scoping was added is still recognized as "already registered".
"""
import json
import os
import sys


def main():
    if len(sys.argv) != 3:
        print("usage: register_stdd_hook.py <settings.json> <hook script>", file=sys.stderr)
        return 1
    settings_path, hook_script = sys.argv[1], sys.argv[2]
    command = "python3 \"%s\"" % hook_script

    if os.path.exists(settings_path):
        with open(settings_path, "r", encoding="utf-8") as fh:
            raw = fh.read().strip()
        try:
            settings = json.loads(raw) if raw else {}
        except json.JSONDecodeError as exc:
            print("ERROR: %s is not valid JSON (%s) — not touching it, register the hook by hand." % (settings_path, exc), file=sys.stderr)
            return 1
    else:
        os.makedirs(os.path.dirname(settings_path), exist_ok=True)
        settings = {}

    hooks = settings.setdefault("hooks", {})
    pretool = hooks.setdefault("PreToolUse", [])

    for entry in pretool:
        for h in entry.get("hooks", []):
            if h.get("command") == command:
                print("already registered: %s" % command)
                return 0

    pretool.append({"matcher": "Write|Edit|NotebookEdit", "hooks": [{"type": "command", "command": command}]})

    tmp_path = settings_path + ".tmp"
    with open(tmp_path, "w", encoding="utf-8") as fh:
        json.dump(settings, fh, indent=2, ensure_ascii=False)
        fh.write("\n")
    os.replace(tmp_path, settings_path)
    print("registered: %s" % command)
    return 0


if __name__ == "__main__":
    sys.exit(main())
