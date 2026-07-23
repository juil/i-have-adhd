# About this fork

Fork of [`ayghri/i-have-adhd`](https://github.com/ayghri/i-have-adhd). The skill
content is unchanged; what this fork adds is **control over when content changes
reach a session.**

## Why

Upstream ships no tags or releases and has sat at `version: 0.1.0` across its
whole history, while `SKILL.md` — the prompt injected into the model's context —
continues to change. Installing from upstream means accepting future edits to
that prompt on upstream's schedule, including changes merged from drive-by pull
requests.

This fork makes the arrival of new content an explicit, reviewable decision.

## How it works

Three layers, each doing one job:

| Layer | Mechanism |
|---|---|
| Provenance | This fork owns the content. Upstream has no push path into it. |
| Version pin | Claude Code installs a versioned plugin into `cache/<marketplace>/<plugin>/<version>/` and leaves it alone until the version changes. |
| Guard | `.github/workflows/version-guard.yml` fails the build if content changed without a bump, or if any declared version drifts. |

The version pin is the load-bearing part, and it is a stock Claude Code
behaviour — upstream simply never used it. The always-on `SessionStart` hook
inherits the pin for free, because `hooks/always-on.sh` resolves `SKILL.md`
relative to `$0`, which lands inside the version-scoped install directory.

## VERSION is the single source of truth

`VERSION` at the repo root. Four files restate it and must agree:

```
.claude-plugin/plugin.json        "version"
.codex-plugin/plugin.json         "version"
gemini-extension.json             "version"
.agents/plugins/marketplace.json  plugins[0].source.ref   (as "vX.Y.Z")
```

That last one is easy to miss and matters most: upstream hardcodes
`ayghri/i-have-adhd.git` @ `main` there. Left as-is, the Antigravity install
route pulls upstream's moving branch directly and defeats the pin. It is
repointed here to this fork at a tag.

`scripts/version_tool.py` owns that file list, in `write` and `check` modes, so
the bump script and CI cannot disagree about which files count.

## Routine tasks

**See what upstream has done, and decide:**

```bash
scripts/sync-upstream.sh
```

Prints the commit list and the full `SKILL.md` diff, then merges only on
explicit confirmation. It does not bump — merging changes the content;
publishing it is separate. That separation is what lets you merge, read it
properly, and release later, or sit on it indefinitely.

**Publish the current content to your sessions:**

```bash
scripts/bump.sh patch      # or minor / major
# edit the CHANGELOG entry it opens, then:
git add -A && git commit -m 'chore(release): vX.Y.Z' && git tag vX.Y.Z
git push origin HEAD --tags
```

**Check the guard locally:**

```bash
python3 scripts/version_tool.py check
```

## Install

```bash
claude plugin marketplace add juil/i-have-adhd
claude plugin install i-have-adhd@i-have-adhd
```

Confirm the pin took by checking the install path resolves to a version
directory rather than `unknown/`:

```bash
ls ~/.claude/plugins/cache/i-have-adhd/i-have-adhd/
# expect: 1.0.0
```

`unknown/` there would mean the version was not read, and the plugin is
tracking commits instead of releases.

Note that upstream and this fork share the marketplace name `i-have-adhd`, so
the two cannot be installed side by side without renaming one.

## Differences from upstream

- Added: `VERSION`, `CHANGELOG.md`, `FORK.md`, `scripts/`, `version-guard.yml`.
- Changed: version strings `0.1.0` → `1.0.0`; `.agents` source repointed to this fork at a tag.
- Removed: `.github/workflows/claude.yml` — triggers on `issue_comment` and reads
  `secrets.CLAUDE_CODE_OAUTH_TOKEN`, which this fork does not hold.
- Unchanged: `skills/i-have-adhd/SKILL.md`, byte for byte.
