# -*- coding: utf-8 -*-
"""
Institution guard — an OPT-IN PreToolUse hook (silent unless TLOR_INSTITUTION_GUARD=1).

Blocks the main session from directly editing institution files
(.claude/rules/*, CLAUDE.md, AGENTS.md). These edits must be dispatched
to a subagent per dispatch.md §1. Subagent calls (identified by agent_id)
are allowed through. Fails open on any error — the guard must never
break a session.
"""
import json
import os
import sys

if os.environ.get("TLOR_INSTITUTION_GUARD") != "1":
    sys.exit(0)

INSTITUTION_PATTERNS = (
    "/.claude/rules/",
    "/CLAUDE.md",
    "/AGENTS.md",
)


def is_institution_file(path):
    """Check if a file path matches institution file patterns."""
    if not path:
        return False
    # Exact filename match for root-level files
    if path == "CLAUDE.md" or path == "AGENTS.md":
        return True
    # Path-based match
    for pattern in INSTITUTION_PATTERNS:
        if pattern in path:
            return True
    return False


def main():
    try:
        data = json.loads(sys.stdin.read() or "{}")
        tool_name = data.get("tool_name", "")
        tool_input = data.get("tool_input", {}) or {}
        agent_id = data.get("agent_id", "")

        # Only guard write operations
        if tool_name not in ("Edit", "Write", "NotebookEdit"):
            return 0

        file_path = tool_input.get("file_path", "") or tool_input.get("notebook_path", "")

        # Only guard institution files
        if not is_institution_file(file_path):
            return 0

        # Subagents (with agent_id) are allowed
        if agent_id:
            return 0

        # Main session trying to edit institution file → deny
        print(json.dumps({
            "hookSpecificOutput": {
                "hookEventName": "PreToolUse",
                "permissionDecision": "deny",
                "permissionDecisionReason": (
                    "Institution file: the main session must not edit "
                    "rules/CLAUDE.md/AGENTS.md inline. Author the full new "
                    "text as a recipe and dispatch it to a subagent "
                    "(dispatch.md §1). This does not block dispatched subagents."
                ),
            }
        }, ensure_ascii=False))
    except Exception:
        pass  # fail-open: guard failure must never block a session
    return 0


if __name__ == "__main__":
    sys.exit(main())
