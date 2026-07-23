# Changelog

Versions in this fork are release decisions, not edit timestamps. Claude Code
installs a versioned plugin into `cache/<marketplace>/<plugin>/<version>/` and
leaves it alone until the version changes — so a bump here is the moment new
content actually reaches a session.

Each entry records the upstream commit it corresponds to, so the provenance of
the injected prompt is always answerable.

## v1.0.0 — 2026-07-23

Initial pinned release of the fork.

- Content identical to upstream `ayghri/i-have-adhd` at `16a42a01f778` (2026-07-23).
  `skills/i-have-adhd/SKILL.md` is byte-for-byte unchanged from upstream.
- Versioning added: `VERSION` as the single source of truth, restated in
  `.claude-plugin/plugin.json`, `.codex-plugin/plugin.json`,
  `gemini-extension.json`, and the `source.ref` of `.agents/plugins/marketplace.json`.
- `.agents/plugins/marketplace.json` repointed from `ayghri/i-have-adhd` @ `main`
  to this fork @ `v1.0.0`. Left unchanged it would have pulled upstream's moving
  `main` directly, bypassing the pin entirely.
- Added `scripts/bump.sh`, `scripts/version_tool.py`, `scripts/sync-upstream.sh`.
- Added `.github/workflows/version-guard.yml`.
- Removed `.github/workflows/claude.yml` — it triggers on `issue_comment` and
  reads `secrets.CLAUDE_CODE_OAUTH_TOKEN`, which this fork does not have.
