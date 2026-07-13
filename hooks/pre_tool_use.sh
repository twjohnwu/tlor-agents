#!/usr/bin/env bash
# pre_tool_use.sh — thin wrapper for institution_guard PreToolUse hook.
# Detects python3 and dispatches to the appropriate implementation.
# Fail-open: if neither python3 nor bash fallback works, exit 0.
HOOK_DIR="$(cd "$(dirname "$0")" && pwd)"
if command -v python3 >/dev/null 2>&1; then
  python3 "$HOOK_DIR/institution_guard.py"
else
  bash "$HOOK_DIR/institution_guard.sh"
fi
