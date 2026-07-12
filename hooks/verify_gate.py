# -*- coding: utf-8 -*-
"""
Verify gate — an OPT-IN Stop hook (silent unless TLOR_VERIFY_GATE=1).

If code files were edited after the last real user prompt and no test
command was run this turn, blocks the turn from ending once
({"decision": "block"}), asking for fail-then-pass evidence. Passes when
stop_hook_active is true (never hard-stuck) and fails open on any error —
the gate must never break a session.

Adapted from verify_gate.py in Miguok/fable-harness
(https://github.com/Miguok/fable-harness), MIT License,
Copyright (c) 2026 Miguok. Adaptations: this header, the opt-in
environment-variable gate below, and an English block message.
"""
import json
import re
import sys
from pathlib import PurePath

import os

if os.environ.get("TLOR_VERIFY_GATE") != "1":
    sys.exit(0)

CODE_EXTS = {
    ".py", ".js", ".ts", ".tsx", ".jsx", ".mjs", ".cjs",
    ".sh", ".ps1", ".psm1", ".vbs",
    ".go", ".rs", ".java", ".c", ".cpp", ".h", ".hpp", ".cs", ".rb", ".sql", ".php",
}

TEST_CMD_RE = re.compile(
    r"(pytest"
    r"|python[3]?(\.exe)?\s+(-m\s+unittest|(\S*[/\\])?(test\S*\.py|\S*_test\.py))"
    r"|npm\s+(run\s+)?test\b|yarn\s+test\b|pnpm\s+(run\s+)?test\b|bun\s+test\b|node\s+--test"
    r"|go\s+test|cargo\s+test|\bvitest\b|\bjest\b"
    r"|mvnw?(\.cmd)?\s+(\S+\s+)*test(\s|$)|gradlew?(\.bat)?\s+(\S+\s+)*test(\s|$)|dotnet\s+test(\s|$)"
    r"|\brspec\b|\bphpunit\b|\bctest\b|make\s+test\b|rake\s+(\S+\s+)*test\b|mix\s+test\b"
    r"|(^|[;&|]\s*)(tox|nox)\b|deno\s+test|rails\s+test)",
    re.IGNORECASE,
)

EDIT_TOOLS = {"Edit", "Write", "NotebookEdit"}
SHELL_TOOLS = {"Bash", "PowerShell"}
LOCAL_COMMAND_PREFIXES = (
    "<command-name>", "<local-command-stdout>",
    "<local-command-stderr>", "<local-command-caveat>",
)


def is_real_user_prompt(entry):
    if entry.get("type") != "user":
        return False
    content = entry.get("message", {}).get("content")
    if not isinstance(content, str):
        return False  # tool_result 列表不是真實 prompt
    return not content.lstrip().startswith(LOCAL_COMMAND_PREFIXES)


def iter_tool_uses(entries):
    for entry in entries:
        if entry.get("type") != "assistant":
            continue
        content = entry.get("message", {}).get("content")
        if not isinstance(content, list):
            continue
        for block in content:
            if isinstance(block, dict) and block.get("type") == "tool_use":
                yield block.get("name", ""), block.get("input", {}) or {}


def analyze(entries):
    """回傳 (本輪修改的程式碼檔名列表, 是否偵測到測試執行)。"""
    last_prompt_idx = -1
    for i, entry in enumerate(entries):
        if is_real_user_prompt(entry):
            last_prompt_idx = i
    current_turn = entries[last_prompt_idx + 1:]

    edited, test_seen = [], False
    for name, tool_input in iter_tool_uses(current_turn):
        if name in EDIT_TOOLS:
            path = tool_input.get("file_path") or tool_input.get("notebook_path") or ""
            if PurePath(path).suffix.lower() in CODE_EXTS:
                edited.append(PurePath(path).name)
        elif name in SHELL_TOOLS:
            if TEST_CMD_RE.search(tool_input.get("command", "")):
                test_seen = True
    return edited, test_seen


def main():
    try:
        data = json.loads(sys.stdin.read() or "{}")
        if data.get("stop_hook_active"):
            return 0
        entries = []
        with open(data["transcript_path"], encoding="utf-8") as f:
            for line in f:
                line = line.strip()
                if not line:
                    continue
                try:
                    entries.append(json.loads(line))
                except json.JSONDecodeError:
                    continue
        edited, test_seen = analyze(entries)
        if edited and not test_seen:
            files = ", ".join(dict.fromkeys(edited))
            print(json.dumps({
                "decision": "block",
                "reason": (
                    f"Verify gate (judgment.md §5 quality floor): code files were edited "
                    f"this turn ({files}) but no test command was detected. Run the relevant "
                    "tests and show fail-then-pass evidence before ending the turn; if tests "
                    "genuinely do not apply (mid-task pause, experimental change), state that "
                    "explicitly and end the turn again to proceed."
                ),
            }, ensure_ascii=False))
    except Exception:
        pass  # fail-open：gate 自身故障不得阻斷 session
    return 0


if __name__ == "__main__":
    sys.exit(main())
