#!/usr/bin/env python3
"""
n8n Workflow Secret Scanner & Cleaner
For the M4 - KI Experte course materials repo.

Scans n8n workflow JSON exports for hardcoded API keys, tokens, and other
secrets that should never be committed to a public repository.

Three modes:
    scan   - read-only report of what was found (no files written)
    apply  - replace findings with descriptive placeholders in a given folder
    inbox  - full inbox flow: scan + clean + archive originals to _processed/

Usage:
    python scripts/scan_secrets.py scan  workflows/
    python scripts/scan_secrets.py apply workflows/ --inplace
    python scripts/scan_secrets.py inbox            # processes ./inbox by default
    python scripts/scan_secrets.py inbox path/to/inbox
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from dataclasses import dataclass
from datetime import datetime
from pathlib import Path
from typing import Callable, Iterator


# ---------------------------------------------------------------------------
# Pattern definitions
# ---------------------------------------------------------------------------
# Each pattern has:
#   - regex:       a compiled regex
#   - label:       human-readable name for the report
#   - placeholder: either a string (used as the replacement) or a callable
#                  that takes the regex match and returns the replacement
# ---------------------------------------------------------------------------

@dataclass
class Pattern:
    regex: re.Pattern
    label: str
    placeholder: str | Callable[[re.Match], str]


def _query_param_placeholder(match: re.Match) -> str:
    """Build a placeholder for URL query-parameter style keys.

    Tries to detect the host within the same string so the placeholder
    is descriptive, e.g. <<REPLACE_WITH_OPENWEATHERMAP_APPID>>.
    """
    param_name = match.group(1).upper()
    full_string = match.string

    host_match = re.search(r"https?://([A-Za-z0-9.\-]+)", full_string)
    if host_match:
        host = host_match.group(1).lower().replace("www.", "")
        parts = host.split(".")
        service = parts[-2] if len(parts) >= 2 else parts[0]
        service = re.sub(r"[^A-Za-z0-9]", "", service).upper()
        return f"{match.group(1)}=<<REPLACE_WITH_{service}_{param_name}>>"

    return f"{match.group(1)}=<<REPLACE_WITH_{param_name}>>"


PATTERNS: list[Pattern] = [
    # --- Provider-specific prefixed keys ---
    Pattern(re.compile(r"sk-ant-[A-Za-z0-9_\-]{20,}"),
            "Anthropic", "<<REPLACE_WITH_ANTHROPIC_KEY>>"),
    Pattern(re.compile(r"sk-or-v1-[A-Za-z0-9]{32,}"),
            "OpenRouter", "<<REPLACE_WITH_OPENROUTER_KEY>>"),
    Pattern(re.compile(r"sk-proj-[A-Za-z0-9_\-]{20,}"),
            "OpenAI (proj key)", "<<REPLACE_WITH_OPENAI_KEY>>"),
    Pattern(re.compile(r"sk-[A-Za-z0-9]{40,}"),
            "OpenAI (or compatible)", "<<REPLACE_WITH_OPENAI_KEY>>"),
    Pattern(re.compile(r"AIza[A-Za-z0-9_\-]{35}"),
            "Google API", "<<REPLACE_WITH_GOOGLE_KEY>>"),
    Pattern(re.compile(r"re_[A-Za-z0-9_]{20,}"),
            "Resend", "<<REPLACE_WITH_RESEND_KEY>>"),
    Pattern(re.compile(r"xox[bpars]-[A-Za-z0-9\-]{20,}"),
            "Slack", "<<REPLACE_WITH_SLACK_TOKEN>>"),
    Pattern(re.compile(r"ghp_[A-Za-z0-9]{36}"),
            "GitHub PAT", "<<REPLACE_WITH_GITHUB_TOKEN>>"),

    # --- JWT-style tokens (Supabase service keys, custom JWTs, etc.) ---
    Pattern(re.compile(r"eyJ[A-Za-z0-9_\-]{10,}\.eyJ[A-Za-z0-9_\-]{10,}\.[A-Za-z0-9_\-]+"),
            "JWT (e.g. Supabase)", "<<REPLACE_WITH_JWT_TOKEN>>"),

    # --- URL query-parameter keys ---
    # Matches ?appid=abc123…, &api_key=…, &access_token=… (value >= 20 chars)
    Pattern(re.compile(r"\b(appid|api_key|apikey|access_token|auth_token)=([A-Za-z0-9_\-]{20,})"),
            "URL Query Parameter", _query_param_placeholder),

    # --- Bearer tokens in header values ---
    Pattern(re.compile(r"Bearer\s+([A-Za-z0-9_\-\.]{30,})"),
            "Bearer Token", "Bearer <<REPLACE_WITH_TOKEN>>"),
]


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

@dataclass
class Finding:
    file: Path
    json_path: str
    pattern_label: str
    snippet: str


def walk_strings(obj, path: str = "$") -> Iterator[tuple[str, str, Callable[[str], None]]]:
    """Recursively yield (json_path, string_value, setter) for every string
    in a nested dict/list. The setter writes a new value back in place.
    """
    if isinstance(obj, dict):
        for k, v in obj.items():
            new_path = f"{path}.{k}"
            if isinstance(v, str):
                def setter(new_value, _k=k, _obj=obj):
                    _obj[_k] = new_value
                yield new_path, v, setter
            else:
                yield from walk_strings(v, new_path)
    elif isinstance(obj, list):
        for i, item in enumerate(obj):
            new_path = f"{path}[{i}]"
            if isinstance(item, str):
                def setter(new_value, _i=i, _obj=obj):
                    _obj[_i] = new_value
                yield new_path, item, setter
            else:
                yield from walk_strings(item, new_path)


def scan_string(s: str) -> list[tuple[Pattern, re.Match]]:
    hits = []
    for pat in PATTERNS:
        for m in pat.regex.finditer(s):
            hits.append((pat, m))
    return hits


def make_snippet(s: str, match: re.Match, context: int = 30) -> str:
    start = max(0, match.start() - context)
    end = min(len(s), match.end() + context)
    prefix = "…" if start > 0 else ""
    suffix = "…" if end < len(s) else ""
    return prefix + s[start:end] + suffix


def redact(snippet: str, match: re.Match) -> str:
    secret = match.group(0)
    masked = secret[:6] + "…" + secret[-2:] if len(secret) > 12 else "***"
    return snippet.replace(secret, masked)


def apply_replacements(s: str) -> tuple[str, int]:
    count = 0
    for pat in PATTERNS:
        if callable(pat.placeholder):
            def repl(m, _pat=pat):
                nonlocal count
                count += 1
                return _pat.placeholder(m)
        else:
            def repl(m, _pat=pat):
                nonlocal count
                count += 1
                return _pat.placeholder
        s = pat.regex.sub(repl, s)
    return s, count


def find_workflow_files(folder: Path, recursive: bool = True) -> list[Path]:
    """Find candidate workflow JSONs. Skips files containing '.cleaned'
    and anything inside an '_processed' folder.
    """
    pattern = "**/*.json" if recursive else "*.json"
    return sorted(
        p for p in folder.glob(pattern)
        if ".cleaned" not in p.name
        and "_processed" not in p.parts
    )


# ---------------------------------------------------------------------------
# Commands
# ---------------------------------------------------------------------------

def cmd_scan(folder: Path) -> int:
    findings: list[Finding] = []
    files = find_workflow_files(folder)

    for file in files:
        try:
            data = json.loads(file.read_text(encoding="utf-8"))
        except json.JSONDecodeError as e:
            print(f"  ⚠️  Skipping {file} (invalid JSON: {e})", file=sys.stderr)
            continue

        for json_path, value, _setter in list(walk_strings(data)):
            for pat, match in scan_string(value):
                snippet = redact(make_snippet(value, match), match)
                findings.append(Finding(file, json_path, pat.label, snippet))

    if not findings:
        print(f"✅ No secrets found in {len(files)} file(s).")
        return 0

    print(f"⚠️  Found {len(findings)} potential secret(s) in {len(files)} file(s):")
    current_file: Path | None = None
    for f in findings:
        if f.file != current_file:
            print(f"\n📄 {f.file}")
            current_file = f.file
        print(f"  • [{f.pattern_label}] at {f.json_path}")
        print(f"      {f.snippet}")
    print(f"\nRun 'apply' to replace these with placeholders.")
    return 1


def cmd_apply(folder: Path, inplace: bool = False) -> int:
    files = find_workflow_files(folder)
    total_changes = 0
    files_changed = 0

    for file in files:
        try:
            data = json.loads(file.read_text(encoding="utf-8"))
        except json.JSONDecodeError as e:
            print(f"  ⚠️  Skipping {file} (invalid JSON: {e})", file=sys.stderr)
            continue

        file_changes = 0
        for _json_path, value, setter in list(walk_strings(data)):
            new_value, n = apply_replacements(value)
            if n > 0:
                setter(new_value)
                file_changes += n

        if file_changes > 0:
            target = file if inplace else file.with_suffix(".cleaned.json")
            target.write_text(
                json.dumps(data, indent=2, ensure_ascii=False),
                encoding="utf-8",
            )
            print(f"✏️  {file} → {target.name} ({file_changes} replacement(s))")
            total_changes += file_changes
            files_changed += 1
        else:
            print(f"✅ {file}: clean")

    print(f"\nDone. {total_changes} replacement(s) across {files_changed} of {len(files)} file(s).")
    return 0


def cmd_inbox(folder: Path) -> int:
    """Full inbox flow: scan, clean, write .cleaned.json next to original,
    then move original to _processed/ for archival.
    """
    if not folder.exists():
        print(f"❌ Inbox folder does not exist: {folder}", file=sys.stderr)
        return 2

    archive_dir = folder / "_processed"
    archive_dir.mkdir(exist_ok=True)

    # Only top-level .json files in the inbox (not in _processed/, not .cleaned)
    files = find_workflow_files(folder, recursive=False)

    if not files:
        print(f"📭 Inbox is empty: no new workflows in {folder}")
        return 0

    print(f"📥 Processing {len(files)} workflow(s) from {folder}\n")

    total_changes = 0
    for file in files:
        try:
            data = json.loads(file.read_text(encoding="utf-8"))
        except json.JSONDecodeError as e:
            print(f"  ⚠️  Skipping {file.name} (invalid JSON: {e})", file=sys.stderr)
            continue

        # Collect findings for the report (before mutation)
        findings_for_file: list[tuple[str, str, str]] = []
        for json_path, value, _setter in list(walk_strings(data)):
            for pat, match in scan_string(value):
                snippet = redact(make_snippet(value, match), match)
                findings_for_file.append((pat.label, json_path, snippet))

        # Apply replacements
        file_changes = 0
        for _json_path, value, setter in list(walk_strings(data)):
            new_value, n = apply_replacements(value)
            if n > 0:
                setter(new_value)
                file_changes += n

        # Write cleaned version
        cleaned_path = file.with_suffix(".cleaned.json")
        cleaned_path.write_text(
            json.dumps(data, indent=2, ensure_ascii=False),
            encoding="utf-8",
        )

        # Archive original — handle name collisions with a timestamp suffix
        archived_path = archive_dir / file.name
        if archived_path.exists():
            ts = datetime.now().strftime("%Y%m%d_%H%M%S")
            archived_path = archive_dir / f"{file.stem}_{ts}{file.suffix}"
        file.rename(archived_path)

        # Report
        print(f"📄 {file.name}")
        if findings_for_file:
            print(f"   🔧 {file_changes} secret(s) replaced:")
            for label, path, snippet in findings_for_file:
                print(f"      • [{label}] {path}")
                print(f"          {snippet}")
        else:
            print(f"   ✅ Already clean (no secrets found)")
        print(f"   → cleaned:  {cleaned_path.name}")
        print(f"   → archived: _processed/{archived_path.name}\n")

        total_changes += file_changes

    print(f"✨ Done. Processed {len(files)} file(s), {total_changes} secret(s) replaced.")
    print(f"   Next step: review the .cleaned.json files, then move each into")
    print(f"   workflows/woche-XX/tag-YY-name/workflow.json and add a README.")
    return 0


# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------

def main() -> None:
    parser = argparse.ArgumentParser(description="n8n workflow secret scanner & cleaner")
    sub = parser.add_subparsers(dest="command", required=True)

    p_scan = sub.add_parser("scan", help="Report findings (read-only)")
    p_scan.add_argument("folder", type=Path)

    p_apply = sub.add_parser("apply", help="Replace findings with placeholders")
    p_apply.add_argument("folder", type=Path)
    p_apply.add_argument("--inplace", action="store_true",
                         help="Overwrite originals instead of writing .cleaned.json")

    p_inbox = sub.add_parser("inbox", help="Process the inbox folder end-to-end")
    p_inbox.add_argument("folder", type=Path, nargs="?", default=Path("inbox"),
                         help="Inbox folder (default: ./inbox)")

    args = parser.parse_args()

    if args.command == "scan":
        if not args.folder.exists():
            print(f"Error: {args.folder} does not exist", file=sys.stderr)
            sys.exit(2)
        sys.exit(cmd_scan(args.folder))
    elif args.command == "apply":
        if not args.folder.exists():
            print(f"Error: {args.folder} does not exist", file=sys.stderr)
            sys.exit(2)
        sys.exit(cmd_apply(args.folder, inplace=args.inplace))
    elif args.command == "inbox":
        sys.exit(cmd_inbox(args.folder))


if __name__ == "__main__":
    main()
