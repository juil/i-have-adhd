#!/usr/bin/env bash
# Show what upstream has changed, and merge it only if you say so.
#
# Usage: scripts/sync-upstream.sh
#
# This fork exists so that upstream edits reach your sessions when YOU decide,
# not when upstream pushes. That guarantee is only as good as this being the
# single way upstream content arrives -- so this script deliberately does two
# things and no more: show the diff, and merge on explicit confirmation.
#
# It does NOT bump the version. Merging changes the content; publishing that
# content to your sessions is a separate decision (scripts/bump.sh). Keeping
# them apart is what lets you merge upstream, read it properly, and only then
# release -- or merge and sit on it indefinitely.

set -euo pipefail

cd "$(dirname "$0")/.."

SKILL=skills/i-have-adhd/SKILL.md

if ! git remote get-url upstream >/dev/null 2>&1; then
  echo "error: no 'upstream' remote. Add it with:" >&2
  echo "  git remote add upstream https://github.com/ayghri/i-have-adhd.git" >&2
  exit 1
fi

echo "fetching upstream..."
git fetch --quiet upstream

behind="$(git rev-list --count HEAD..upstream/main)"
if [ "$behind" -eq 0 ]; then
  echo "Already current with upstream/main. Nothing to do."
  exit 0
fi

echo
echo "=============================================================="
echo " $behind upstream commit(s) not in this fork"
echo "=============================================================="
git --no-pager log --oneline --no-merges HEAD..upstream/main | sed 's/^/  /'

echo
echo "=============================================================="
echo " SKILL.md diff  (the payload injected into every session)"
echo "=============================================================="
if git diff --quiet HEAD upstream/main -- "$SKILL"; then
  echo "  (no change to SKILL.md -- upstream moved only docs/CI/tooling)"
else
  git --no-pager diff HEAD upstream/main -- "$SKILL"
fi

echo
echo "=============================================================="
echo " Other changed files"
echo "=============================================================="
git --no-pager diff --stat HEAD upstream/main -- . ":(exclude)$SKILL" | sed 's/^/  /'

echo
printf 'Merge upstream/main into %s? [y/N] ' "$(git branch --show-current)"
read -r reply
case "$reply" in
  y | Y | yes | YES) ;;
  *) echo "Aborted. Nothing merged."; exit 0 ;;
esac

git merge --no-ff upstream/main -m "Merge upstream/main into fork"

echo
echo "Merged. Content has changed but is NOT yet published to your sessions."
echo "When you are ready to publish, run:  scripts/bump.sh <major|minor|patch>"
