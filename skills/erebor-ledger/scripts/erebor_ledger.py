#!/usr/bin/env python3
"""erebor-ledger usage report — token/cost savings from tlor-orchestration dispatch.

Reads Claude Code transcript JSONL files (main-session + subagent) and
answers two independent questions (per erebor-ledger spec §1/§3):

  1. When Fable 5 is the orchestrator, how much token/cost did dispatching
     to tlor-orchestration save versus doing the work inline?
  2. Same question when any Opus version is the orchestrator?

The two groups are reported and totalled SEPARATELY — they are never
averaged or merged (spec §1, §3). Sessions whose orchestrator model is
neither `claude-fable-5*` nor `claude-opus-*` (e.g. a sonnet orchestrator)
fall into "other" and are excluded from both reports.

python3 stdlib only — no pip dependencies.
"""

from __future__ import annotations

import argparse
import json
import os
import sys
from collections import Counter, defaultdict
from datetime import datetime

TLOR_ROLES = [
    "rohirrim-outrider",
    "ranger-pathfinder",
    "noldor-loremaster",
    "dwarf-smith",
    "gondor-builder",
    "eagle-sentinel",
    "elf-archer",
    "orc-saboteur",
    "hobbit-gardener",
]
OTHER_ROLE_LABEL = "(other subagents)"
SYNTHETIC_MODEL = "<synthetic>"

COUNTERFACTUAL_DISCLOSURE = (
    "Counterfactual assumes inline execution would consume the same token"
    " volume; this is an estimate, not a measurement."
)
CACHE_TIER_DISCLOSURE = (
    "Cache-write assumption: transcripts don't record whether a cache write"
    " used the 5m or 1h tier, so this report prices every cache write at the"
    " 5m tier; this is an assumption, not a measurement."
)

TOKEN_FIELDS = ("input", "output", "cache_write", "cache_read")

DEFAULT_ROOT = os.path.expanduser("~/.claude/projects")
PRICE_TABLE_PATH = os.path.join(
    os.path.dirname(os.path.abspath(__file__)), "..", "references", "model-prices.json"
)


# --------------------------------------------------------------------------
# Pricing
# --------------------------------------------------------------------------

def load_price_table(path: str = PRICE_TABLE_PATH) -> dict:
    with open(path, "r", encoding="utf-8") as f:
        data = json.load(f)
    data.pop("_meta", None)
    return data


def resolve_price(model: str | None, price_table: dict, today: str) -> dict | None:
    """Longest-prefix match of `model` against price_table keys.

    Returns the price entry dict, or None if no key is a prefix of `model`
    (per spec §6: unknown model SHALL NOT be priced by guessing).
    """
    if not model:
        return None
    best_key = None
    for key in price_table:
        if model.startswith(key):
            if best_key is None or len(key) > len(best_key):
                best_key = key
    if best_key is None:
        return None
    entry = price_table[best_key]
    next_tier = entry.get("next_tier")
    if next_tier and next_tier.get("effective_from") and today >= next_tier["effective_from"]:
        return next_tier
    return entry


def zero_tokens() -> dict:
    return {k: 0 for k in TOKEN_FIELDS}


def add_tokens(dst: dict, src: dict) -> None:
    for k in TOKEN_FIELDS:
        dst[k] += src.get(k, 0)


def usage_to_tokens(usage: dict) -> dict:
    return {
        "input": usage.get("input_tokens", 0) or 0,
        "output": usage.get("output_tokens", 0) or 0,
        "cache_write": usage.get("cache_creation_input_tokens", 0) or 0,
        "cache_read": usage.get("cache_read_input_tokens", 0) or 0,
    }


def cost_for_tokens(tokens: dict, price_entry: dict | None) -> float | None:
    """input/output/cache_read/cache_write priced SEPARATELY then summed
    (spec §4 — no single blended rate)."""
    if price_entry is None:
        return None
    return (
        tokens["input"] / 1_000_000 * price_entry["input"]
        + tokens["output"] / 1_000_000 * price_entry["output"]
        + tokens["cache_write"] / 1_000_000 * price_entry["cache_write"]
        + tokens["cache_read"] / 1_000_000 * price_entry["cache_read"]
    )


# --------------------------------------------------------------------------
# Transcript walking
# --------------------------------------------------------------------------

def iter_assistant_records(path: str, since: str | None, warnings: list):
    """Yield (model, tokens) for each non-synthetic assistant record.

    Timestamp filtering: transcripts on this machine reliably carry a
    top-level ISO `timestamp` field (spec §7 requires confirming this before
    relying on it). A record missing `timestamp` while --since is active is
    excluded (fail closed) rather than silently included, and warned once.
    """
    try:
        f = open(path, "r", encoding="utf-8")
    except OSError:
        return
    with f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            try:
                rec = json.loads(line)
            except json.JSONDecodeError:
                continue
            if rec.get("type") != "assistant":
                continue
            message = rec.get("message") or {}
            model = message.get("model")
            if model == SYNTHETIC_MODEL:
                continue
            if since is not None:
                ts = rec.get("timestamp")
                if not ts:
                    warnings.append(
                        f"WARNING: record without timestamp in {path} excluded under --since"
                        " (transcript timestamp field assumed reliable on this machine;"
                        " see spec §7 mtime-fallback clause)"
                    )
                    continue
                if ts[:10] < since:
                    continue
            usage = message.get("usage") or {}
            yield model, usage_to_tokens(usage)


def classify_group(model: str | None) -> str:
    if not model:
        return "other"
    if model.startswith("claude-fable-5"):
        return "fable"
    if model.startswith("claude-opus-"):
        return "opus"
    return "other"


def find_project_dirs(root: str, project_filter: str | None):
    if not os.path.isdir(root):
        return
    for name in sorted(os.listdir(root)):
        full = os.path.join(root, name)
        if not os.path.isdir(full):
            continue
        if project_filter and project_filter not in name:
            continue
        yield name, full


def find_main_sessions(project_dir: str):
    for name in sorted(os.listdir(project_dir)):
        if name.endswith(".jsonl"):
            yield name[: -len(".jsonl")], os.path.join(project_dir, name)


def find_subagent_files(project_dir: str, session_id: str):
    subdir = os.path.join(project_dir, session_id, "subagents")
    if not os.path.isdir(subdir):
        return
    for name in sorted(os.listdir(subdir)):
        if name.endswith(".jsonl"):
            agent_file = os.path.join(subdir, name)
            meta_file = os.path.join(subdir, name[: -len(".jsonl")] + ".meta.json")
            yield agent_file, meta_file


def load_agent_type(meta_file: str, warnings: list) -> str:
    try:
        with open(meta_file, "r", encoding="utf-8") as f:
            meta = json.load(f)
        return meta.get("agentType") or OTHER_ROLE_LABEL
    except (OSError, json.JSONDecodeError):
        warnings.append(f"WARNING: missing/unreadable meta file {meta_file} — treated as {OTHER_ROLE_LABEL}")
        return OTHER_ROLE_LABEL


# --------------------------------------------------------------------------
# Aggregation
# --------------------------------------------------------------------------

def new_group_state() -> dict:
    return {
        "sessions": 0,
        "orch_tokens": zero_tokens(),
        "orch_cost": 0.0,
        "orch_priced_sessions": 0,
        "orch_unpriced_sessions": 0,
        "roles": defaultdict(new_role_row),
        "project_saved": defaultdict(float),
    }


def new_role_row() -> dict:
    return {
        "dispatches": 0,
        "tokens": zero_tokens(),
        "actual_cost": 0.0,
        "counterfactual_cost": 0.0,
        "na": False,
    }


def build_report(root: str, project_filter: str | None, since: str | None, price_table: dict, today: str):
    warnings: list[str] = []
    groups = {"fable": new_group_state(), "opus": new_group_state()}

    for project_name, project_dir in find_project_dirs(root, project_filter):
        for session_id, session_path in find_main_sessions(project_dir):
            main_records = list(iter_assistant_records(session_path, since, warnings))
            if not main_records:
                continue

            model_counts = Counter(m for m, _ in main_records)
            orchestrator_model = model_counts.most_common(1)[0][0]
            group_name = classify_group(orchestrator_model)
            if group_name == "other":
                continue

            g = groups[group_name]
            g["sessions"] += 1

            orch_tokens = zero_tokens()
            for _, tok in main_records:
                add_tokens(orch_tokens, tok)
            add_tokens(g["orch_tokens"], orch_tokens)

            orch_price = resolve_price(orchestrator_model, price_table, today)
            if orch_price is None:
                warnings.append(
                    f"WARNING: unpriced orchestrator model '{orchestrator_model}'"
                    f" (session {session_id}, project {project_name}) — orchestrator cost N/A"
                )
                g["orch_unpriced_sessions"] += 1
            else:
                g["orch_cost"] += cost_for_tokens(orch_tokens, orch_price)
                g["orch_priced_sessions"] += 1

            for agent_file, meta_file in find_subagent_files(project_dir, session_id):
                agent_type = load_agent_type(meta_file, warnings)
                role = agent_type if agent_type in TLOR_ROLES else OTHER_ROLE_LABEL
                sub_records = list(iter_assistant_records(agent_file, since, warnings))
                if not sub_records:
                    continue

                row = g["roles"][role]
                row["dispatches"] += 1

                agent_tokens = zero_tokens()
                actual_cost = 0.0
                row_na = orch_price is None
                for model, tok in sub_records:
                    add_tokens(agent_tokens, tok)
                    price = resolve_price(model, price_table, today)
                    if price is None:
                        row_na = True
                        warnings.append(
                            f"WARNING: unpriced model '{model}' in {os.path.basename(agent_file)}"
                            f" (role {role}, project {project_name}) — cost N/A for this row"
                        )
                        continue
                    actual_cost += cost_for_tokens(tok, price)

                add_tokens(row["tokens"], agent_tokens)
                if row_na:
                    row["na"] = True
                else:
                    row["actual_cost"] += actual_cost
                    counterfactual = cost_for_tokens(agent_tokens, orch_price)
                    row["counterfactual_cost"] += counterfactual
                    g["project_saved"][project_name] += counterfactual - actual_cost

    return groups, warnings


# --------------------------------------------------------------------------
# Rendering
# --------------------------------------------------------------------------

def fmt_int(n: int) -> str:
    return f"{n:,}"


def fmt_money(n: float | None) -> str:
    if n is None:
        return "N/A"
    return f"${n:,.2f}"


def fmt_pct(saved: float | None, counterfactual: float | None) -> str:
    if saved is None or counterfactual is None or counterfactual == 0:
        return "N/A"
    return f"{saved / counterfactual * 100:.1f}%"


def render_group(label: str, g: dict) -> str:
    lines = []
    lines.append(f"## {label} group per-role table")
    lines.append("")
    lines.append(
        "| Role | Dispatches | input | output | cache(r/w) | Actual cost | Counterfactual cost | money saved | saved % |"
    )
    lines.append("|---|---|---|---|---|---|---|---|---|")

    ordered_roles = [r for r in TLOR_ROLES if r in g["roles"]]
    if OTHER_ROLE_LABEL in g["roles"]:
        ordered_roles.append(OTHER_ROLE_LABEL)

    total_dispatches = 0
    total_actual = 0.0
    total_counterfactual = 0.0
    any_na = False
    any_priced = False

    for role in ordered_roles:
        row = g["roles"][role]
        total_dispatches += row["dispatches"]
        cache_cell = f"{fmt_int(row['tokens']['cache_read'])}/{fmt_int(row['tokens']['cache_write'])}"
        if row["na"]:
            any_na = True
            lines.append(
                f"| {role} | {row['dispatches']} | {fmt_int(row['tokens']['input'])} | "
                f"{fmt_int(row['tokens']['output'])} | {cache_cell} | N/A | N/A | N/A | N/A |"
            )
        else:
            any_priced = True
            saved = row["counterfactual_cost"] - row["actual_cost"]
            total_actual += row["actual_cost"]
            total_counterfactual += row["counterfactual_cost"]
            lines.append(
                f"| {role} | {row['dispatches']} | {fmt_int(row['tokens']['input'])} | "
                f"{fmt_int(row['tokens']['output'])} | {cache_cell} | {fmt_money(row['actual_cost'])} | "
                f"{fmt_money(row['counterfactual_cost'])} | {fmt_money(saved)} | "
                f"{fmt_pct(saved, row['counterfactual_cost'])} |"
            )

    partial_note = "(partial — excludes N/A rows above)" if any_na else ""
    if any_priced:
        total_saved = total_counterfactual - total_actual
        total_actual_cell = fmt_money(total_actual)
        total_counterfactual_cell = fmt_money(total_counterfactual)
        total_saved_cell = fmt_money(total_saved)
        total_pct_cell = fmt_pct(total_saved, total_counterfactual)
    else:
        # No row in this group had a fully-priced model — do not print "$0.00",
        # which would misleadingly read as "zero savings" rather than "unknown".
        total_saved = None
        total_actual_cell = total_counterfactual_cell = total_saved_cell = total_pct_cell = "N/A"
    lines.append(
        f"| **Total saved** {partial_note} | **{total_dispatches}** | — | — | — | "
        f"**{total_actual_cell}** | **{total_counterfactual_cell}** | "
        f"**{total_saved_cell}** | **{total_pct_cell}** |"
    )
    lines.append("")

    orch_cost_display = fmt_money(g["orch_cost"])
    if g["orch_unpriced_sessions"]:
        orch_cost_display += (
            f" (partial — {g['orch_priced_sessions']}/{g['sessions']} sessions priced,"
            f" {g['orch_unpriced_sessions']} orchestrator model(s) unpriced, see warnings)"
        )
    lines.append(
        f"Group summary: {label} group: {g['sessions']} sessions, orchestrator "
        f"cumulative {fmt_int(g['orch_tokens']['input'])} input / "
        f"{fmt_int(g['orch_tokens']['output'])} output tokens, cost {orch_cost_display}; "
        f"this group's Total saved = {fmt_money(total_saved)}"
        f"{' (partial)' if any_na else ''}"
    )
    lines.append("")

    if g["project_saved"]:
        parts = "; ".join(
            f"{proj}: {fmt_money(saved)}" for proj, saved in sorted(g["project_saved"].items())
        )
        lines.append(f"Per-project subtotal (priced rows only): {parts}")
    else:
        lines.append("Per-project subtotal: (no priced dispatch records)")
    lines.append("")
    return "\n".join(lines)


def render_report(groups: dict, warnings: list, since: str | None) -> str:
    lines = []
    lines.append("# erebor-ledger usage report")
    lines.append("")
    lines.append(f"> {COUNTERFACTUAL_DISCLOSURE}")
    lines.append(f"> {CACHE_TIER_DISCLOSURE}")
    if since:
        lines.append(f"> Filter: --since {since} (per the transcript's own `timestamp` field)")
    lines.append("")
    lines.append(render_group("Fable", groups["fable"]))
    lines.append(render_group("Opus", groups["opus"]))

    if warnings:
        lines.append("## Warnings")
        lines.append("")
        for w in warnings:
            lines.append(f"- {w}")
        lines.append("")

    return "\n".join(lines)


# --------------------------------------------------------------------------
# CLI
# --------------------------------------------------------------------------

def main(argv=None):
    parser = argparse.ArgumentParser(
        description=(
            "erebor-ledger: report token/cost savings from tlor-orchestration dispatch, "
            "grouped by orchestrator model (Fable 5 vs Opus)."
        )
    )
    parser.add_argument(
        "--project",
        help="only include project directories whose name contains this substring",
    )
    parser.add_argument(
        "--since",
        help="YYYY-MM-DD; only include records at or after this date (transcript timestamp)",
    )
    parser.add_argument(
        "--root",
        help=(
            "advanced/testing only: override the transcripts root directory "
            f"(default: {DEFAULT_ROOT})"
        ),
    )
    args = parser.parse_args(argv)

    root = os.path.expanduser(args.root) if args.root else DEFAULT_ROOT
    price_table = load_price_table()
    today = datetime.now().strftime("%Y-%m-%d")

    groups, warnings = build_report(root, args.project, args.since, price_table, today)
    print(render_report(groups, warnings, args.since))

    return 0


if __name__ == "__main__":
    sys.exit(main())
