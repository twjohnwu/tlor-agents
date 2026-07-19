# -*- coding: utf-8 -*-
"""
STDD test-file guard — an opt-in PreToolUse hook (only wired when the user
runs `install.sh --install-hook`).

Scope (STDD/spec.md REQ-09, specs/stdd-execute.md S-14): once Dispatch A
(builder-RED) establishes a RED fingerprint baseline for a test file, that
file SHALL NOT be written again before its owning task is marked `[x]` in
`tasks.md`. This hook enforces that ONE thing — it does NOT protect
frontmatter/`status`/fingerprint fields (REQ-09 explicitly excludes those;
see STDD/spec.md "REQ-09" and specs/stdd-spec.md S-05, which rely only on
user approval + `stdd-lint` after-the-fact comparison).

HEURISTIC / documented limitation: `specs/stdd-plan.md` S-07 mandates that
every TDD task in `tasks.md` names its exact test file and carries a
`[ ]`/`[wip]`/`[x]` status marker, but does not fix a literal line syntax
for either field. There is also no separate baseline-fingerprint file on
disk (the fingerprint is deliberately passed through the dispatch prompt
only, per S-14, so a builder can't tamper with a stored copy). So this
hook approximates "has an established RED baseline" as: the target file
path appears inside a backtick-quoted span in the same task block as a
`[wip]` marker, in any `STDD/*/tasks.md` under the current working
directory. If a project's tasks.md uses a different convention this
detector will under- or over-match — flagged here rather than silently
assumed correct.

Escape hatch for the one sanctioned exception (S-17 plan-drift recovery,
where Dispatch A is authorized to overwrite the same-named test file):
set TLOR_STDD_ALLOW_TEST_REWRITE=1 for that one recovery dispatch. The
mechanical layer cannot itself distinguish an authorized recovery rewrite
from an unauthorized one (per spec, it isn't required to) — a human
(the main session, per dispatch discipline) toggles this env var only for
the recovery call.

Fails open on any error — the guard must never break a session.
"""
import json
import os
import re
import sys

STATUS_RE = re.compile(r"\[( |wip|x)\]")
BACKTICK_RE = re.compile(r"`([^`]+)`")
TEST_HINTS = ("test", "spec", "_test.", ".test.", "test_")


def _is_probably_test_path(candidate):
    lowered = candidate.lower()
    return any(hint in lowered for hint in TEST_HINTS)


def _find_tasks_md(start_dir):
    """Find tasks.md files under any STDD/<name>/ change directory below
    start_dir, per specs/stdd-plan.md S-07's fixed output path."""
    found = []
    for root, dirs, files in os.walk(start_dir):
        # skip hidden/vendor dirs to keep this cheap
        dirs[:] = [d for d in dirs if not d.startswith(".") and d not in ("node_modules", "vendor")]
        if "tasks.md" in files and "STDD" in root.split(os.sep):
            found.append(os.path.join(root, "tasks.md"))
    return found


def _wip_protected_paths(tasks_md_path):
    """Return the set of test-file path fragments referenced inside any
    [wip]-marked task block of this tasks.md."""
    protected = set()
    try:
        with open(tasks_md_path, "r", encoding="utf-8") as fh:
            lines = fh.readlines()
    except OSError:
        return protected

    block = []
    block_is_wip = False

    def flush():
        if block_is_wip:
            for line in block:
                for m in BACKTICK_RE.finditer(line):
                    cand = m.group(1).strip()
                    if _is_probably_test_path(cand):
                        protected.add(cand)

    for line in lines:
        m = STATUS_RE.search(line)
        if m and ("- [" in line or line.strip().startswith("[")):
            # a new task line starts here — flush the previous block first
            flush()
            block = [line]
            block_is_wip = m.group(1) == "wip"
        else:
            block.append(line)
    flush()
    return protected


def is_protected_write(file_path, cwd):
    if not file_path:
        return False
    search_root = cwd or os.getcwd()
    for tasks_md in _find_tasks_md(search_root):
        for candidate in _wip_protected_paths(tasks_md):
            if file_path.endswith(candidate) or candidate.endswith(os.path.basename(file_path)):
                return True
    return False


def main():
    try:
        data = json.loads(sys.stdin.read() or "{}")
        tool_name = data.get("tool_name", "")
        tool_input = data.get("tool_input", {}) or {}
        cwd = data.get("cwd", "")

        if tool_name not in ("Edit", "Write", "NotebookEdit"):
            return 0

        if os.environ.get("TLOR_STDD_ALLOW_TEST_REWRITE") == "1":
            return 0

        file_path = tool_input.get("file_path", "") or tool_input.get("notebook_path", "")
        if not is_protected_write(file_path, cwd):
            return 0

        print(json.dumps({
            "hookSpecificOutput": {
                "hookEventName": "PreToolUse",
                "permissionDecision": "deny",
                "permissionDecisionReason": (
                    "STDD test-file guard: this test file has an established "
                    "RED fingerprint baseline ([wip] task in tasks.md) — "
                    "further writes are blocked until the task is marked "
                    "[x] (REQ-09 / specs/stdd-execute.md S-14). The only "
                    "sanctioned exception is the S-17 plan-drift recovery "
                    "rewrite by Dispatch A; for that one call set "
                    "TLOR_STDD_ALLOW_TEST_REWRITE=1."
                ),
            }
        }, ensure_ascii=False))
    except Exception:
        pass  # fail-open: guard failure must never block a session
    return 0


if __name__ == "__main__":
    sys.exit(main())
