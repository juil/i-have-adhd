#!/usr/bin/env bash
# Bump the plugin version everywhere it is declared, then commit and tag.
#
# Usage: scripts/bump.sh <major|minor|patch>
#
# VERSION is the single source of truth. Four other files must agree with it:
#   .claude-plugin/plugin.json   "version"
#   .codex-plugin/plugin.json    "version"
#   gemini-extension.json        "version"
#   .agents/plugins/marketplace.json  plugins[0].source.ref  (as "vX.Y.Z")
#
# The version string is what actually gates updates: Claude Code installs a
# versioned plugin into cache/<marketplace>/<plugin>/<version>/ and leaves it
# alone until the version changes. Bumping is therefore a deliberate act of
# publishing, never a side effect of editing content.

set -euo pipefail

cd "$(dirname "$0")/.."

part="${1:-}"
case "$part" in
  major|minor|patch) ;;
  *) echo "usage: scripts/bump.sh <major|minor|patch>" >&2; exit 2 ;;
esac

if [ -n "$(git status --porcelain)" ]; then
  echo "error: working tree is dirty. Commit or stash first." >&2
  exit 1
fi

current="$(tr -d '[:space:]' < VERSION)"
IFS=. read -r maj min pat <<EOF
$current
EOF

case "$part" in
  major) maj=$((maj + 1)); min=0; pat=0 ;;
  minor) min=$((min + 1)); pat=0 ;;
  patch) pat=$((pat + 1)) ;;
esac
next="${maj}.${min}.${pat}"

echo "$current -> $next"

printf '%s\n' "$next" > VERSION
python3 scripts/version_tool.py write "$next"

# CHANGELOG: open a new section for this version, keeping provenance visible.
upstream_sha="$(git rev-parse --short=12 upstream/main 2>/dev/null || echo 'not-fetched')"
tmp="$(mktemp)"
{
  printf '## v%s — %s\n\n' "$next" "$(date +%Y-%m-%d)"
  printf -- '- Upstream ref at time of release: `%s`\n' "$upstream_sha"
  printf -- '- <describe what changed in SKILL.md, or "no content change">\n\n'
  cat CHANGELOG.md
} > "$tmp"
mv "$tmp" CHANGELOG.md

echo
echo "Edit the CHANGELOG entry, then:"
echo "  git add -A && git commit -m 'chore(release): v$next' && git tag v$next"
echo "  git push origin HEAD --tags"
