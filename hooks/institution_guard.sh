#!/usr/bin/env bash
# Institution guard — bash fallback (active only when TLOR_INSTITUTION_GUARD=1).
# Blocks main session from editing institution files. Subagents pass through.
# Fail-open on any error.
[ "${TLOR_INSTITUTION_GUARD}" = "1" ] || exit 0
set -euo pipefail
command -v jq >/dev/null 2>&1 || exit 0
input=$(cat)
tool_name=$(printf '%s' "$input" | jq -r '.tool_name // empty')
case "$tool_name" in
  Edit|Write|NotebookEdit) ;;
  *) exit 0 ;;
esac
file=$(printf '%s' "$input" | jq -r '.tool_input.file_path // .tool_input.notebook_path // empty')
agent_id=$(printf '%s' "$input" | jq -r '.agent_id // empty')
[ -n "$file" ] || exit 0
# Subagents are allowed
[ -z "$agent_id" ] || exit 0
# Check institution file patterns
case "$file" in
  */.claude/rules/*|*/CLAUDE.md|CLAUDE.md|*/AGENTS.md|AGENTS.md)
    jq -n '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"deny",permissionDecisionReason:"Institution file: the main session must not edit rules/CLAUDE.md/AGENTS.md inline. Author the full new text as a recipe and dispatch it to a subagent (dispatch.md §1). This does not block dispatched subagents."}}'
    exit 0
    ;;
esac
exit 0
