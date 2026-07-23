#!/usr/bin/env python3
"""Keep every declared version in this repo in agreement with VERSION.

VERSION (repo root) is the single source of truth. Four other files restate it:

  .claude-plugin/plugin.json        "version": "X.Y.Z"
  .codex-plugin/plugin.json         "version": "X.Y.Z"
  gemini-extension.json             "version": "X.Y.Z"
  .agents/plugins/marketplace.json  plugins[0].source.ref == "vX.Y.Z"

Two modes, sharing the list above so they can never drift apart:

  version_tool.py write X.Y.Z   rewrite all four to X.Y.Z   (used by scripts/bump.sh)
  version_tool.py check         exit 1 if any disagrees      (used by CI)

Edits are done with a targeted regex rather than json.load/json.dump so that
formatting, key order, and comments survive untouched. A substitution that
matches nothing is an error, not a silent no-op -- that is the failure mode
this tool exists to prevent.
"""

from __future__ import annotations

import json
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent

# (path, human label, regex with one capture group for the prefix, value template)
VERSION_FIELDS = [
    (".claude-plugin/plugin.json", 'version', r'("version"\s*:\s*)"[^"]*"', '{v}'),
    (".codex-plugin/plugin.json", 'version', r'("version"\s*:\s*)"[^"]*"', '{v}'),
    ("gemini-extension.json", 'version', r'("version"\s*:\s*)"[^"]*"', '{v}'),
    (".agents/plugins/marketplace.json", 'source.ref', r'("ref"\s*:\s*)"[^"]*"', 'v{v}'),
]

SEMVER = re.compile(r"^\d+\.\d+\.\d+$")


def read_version() -> str:
    v = (ROOT / "VERSION").read_text().strip()
    if not SEMVER.match(v):
        sys.exit(f"VERSION is not semver: {v!r}")
    return v


def write(version: str) -> int:
    if not SEMVER.match(version):
        sys.exit(f"not semver: {version!r}")
    for rel, label, pattern, tmpl in VERSION_FIELDS:
        path = ROOT / rel
        src = path.read_text()
        want = tmpl.format(v=version)
        new, n = re.subn(pattern, lambda m: f'{m.group(1)}"{want}"', src, count=1)
        if n != 1:
            sys.exit(f"{rel}: expected exactly 1 {label} match, got {n}")
        path.write_text(new)
        print(f"  {rel}: {label} -> {want}")
    return 0


def check() -> int:
    version = read_version()
    problems = []
    for rel, label, _pattern, tmpl in VERSION_FIELDS:
        path = ROOT / rel
        if not path.exists():
            problems.append(f"{rel}: missing")
            continue
        data = json.loads(path.read_text())
        if label == "version":
            actual = data.get("version")
        else:
            actual = data["plugins"][0]["source"]["ref"]
        want = tmpl.format(v=version)
        if actual != want:
            problems.append(f"{rel}: {label} is {actual!r}, VERSION implies {want!r}")

    if problems:
        print(f"version-guard FAILED (VERSION = {version})", file=sys.stderr)
        for p in problems:
            print(f"  - {p}", file=sys.stderr)
        print("\nFix with: scripts/bump.sh <part>, or edit to match VERSION.", file=sys.stderr)
        return 1

    print(f"version-guard OK: all {len(VERSION_FIELDS)} declarations agree on {version}")
    return 0


def main() -> int:
    if len(sys.argv) < 2:
        sys.exit(__doc__)
    mode = sys.argv[1]
    if mode == "write":
        if len(sys.argv) != 3:
            sys.exit("usage: version_tool.py write X.Y.Z")
        return write(sys.argv[2])
    if mode == "check":
        return check()
    sys.exit(f"unknown mode: {mode!r}")


if __name__ == "__main__":
    raise SystemExit(main())
