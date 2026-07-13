---
name: sync-docs
description: >
  Audits AGENTS.md and .github/copilot-instructions.md against the actual
  codebase, fixes any stale content, updates CHANGELOG.md [Unreleased], then
  commits and pushes. Use when constants change, functions are added/renamed,
  install paths shift, or after any structural refactor. Trigger phrases:
  "sync docs", "update agents", "update copilot instructions", "self-improve
  docs", "update docs before commit", "sync docs and push".
compatibility: "requires: git, gh CLI"
---

# sync-docs — Keep AI guidance files accurate

Audit the three AI-guidance files against the actual source, patch anything
stale, update `CHANGELOG.md`, commit, and push. Work through every phase in
order; stop and surface errors immediately when they occur.

---

## Phase 1 — Ground truth extraction

Read the source files that documentation describes. Pull out the exact current
values; do **not** rely on what the docs already say.

```bash
# Constants
grep -E '^readonly (SUPPORTED_ADAPTERS|SUPPORTED_OS_VERSIONS|LOOP_PREVENTION_DELAY)' wireless.sh

# Function signatures
grep -E '^[a-z_]+\(\)' wireless.sh

# Install paths (target dir, plist destination)
grep -E 'SCRIPTS_DIR|LAUNCH_DAEMONS_DIR|/Library/' install.sh | head -20

# Plist program argument path
grep -A2 'ProgramArguments' com.computernetworkbasics.wifionoff.plist

# ThrottleInterval
grep -A1 'ThrottleInterval' com.computernetworkbasics.wifionoff.plist

# KeepAlive value
grep -A1 'KeepAlive' com.computernetworkbasics.wifionoff.plist
```

Record the live values as your reference for every check in Phase 2.

---

## Phase 2 — Audit AGENTS.md

Read `AGENTS.md` in full, then check each item below against the live values
from Phase 1. For each check, note **STALE**, **MISSING**, or **OK**.

| # | What to check | Where in AGENTS.md |
|---|---|---|
| 1 | Supported macOS list (Sonoma/Sequoia/Tahoe + kernel numbers) | Line 7 (`**Supported macOS:**`) |
| 2 | `SUPPORTED_ADAPTERS` value in Constants section | `### Constants` |
| 3 | `SUPPORTED_OS_VERSIONS` value in Constants section | `### Constants` |
| 4 | `LOOP_PREVENTION_DELAY` value in Constants section | `### Constants` |
| 5 | Network Detection Flow diagram — function names match `wireless.sh` | `### Network Detection Flow` |
| 6 | Network Detection Flow diagram — `toggle_wifi` description is accurate | `### Network Detection Flow` |
| 7 | Install locations: scripts path and plist path | `**Install locations**` |
| 8 | LaunchDaemon behavior notes (KeepAlive, watch path, sleep seconds) | `### LaunchDaemon Behavior` |
| 9 | Common Pitfalls — each pitfall matches current code behaviour | `## Common Pitfalls` |
| 10 | CI/CD table — workflow triggers and descriptions still accurate | `## CI/CD` |
| 11 | Repository structure tree — no new files missing, no deleted files listed | `## Repository Structure` |
| 12 | `validate.yml` adapter grep step (if adapter list changed) | `## Adding New Adapter Support` |
| 13 | Step 5 in "Adding New macOS Version" — file references are correct | `## Adding New macOS Version Support` |

---

## Phase 3 — Audit .github/copilot-instructions.md

Read `.github/copilot-instructions.md` in full, then check:

| # | What to check |
|---|---|
| 1 | Compatibility Notes line — OS version list matches `SUPPORTED_OS_VERSIONS` |
| 2 | Adapter list — matches `SUPPORTED_ADAPTERS` |
| 3 | Maintenance Matrix rows — file references and update targets still exist |
| 4 | `LOOP_PREVENTION_DELAY` mention (sleep delay note) — matches actual value |
| 5 | Install paths in "Installation Structure" section — match `install.sh` |

---

## Phase 4 — Apply fixes

For each STALE or MISSING item from Phase 2 and 3:

1. Edit the file using the file editing tool (never shell redirection / heredoc).
2. Preserve surrounding context exactly — only change the stale value.
3. After every edit, re-read the changed section to confirm the fix landed correctly.

**Do not** rewrite whole sections, change prose style, or touch anything that
audited as OK.

---

## Phase 5 — Update CHANGELOG.md

Open `CHANGELOG.md`. Under `## [Unreleased]`:

- Add a `### Changed` entry (or append to an existing one) that lists each
  doc file updated and a one-line summary of what changed.
  Example: `- \`AGENTS.md\`: updated \`SUPPORTED_OS_VERSIONS\` to include kernel 26 (macOS Tahoe 16.x)`
- Use plain English, user-visible perspective.
- Omit entries for checks that were already OK — only log real changes.
- If `## [Unreleased]` does not exist, add it above the first versioned section.

---

## Phase 6 — Stage, commit, and push

```bash
# 1. Preview what changed
git diff AGENTS.md .github/copilot-instructions.md CHANGELOG.md

# 2. Stage only the doc files
git add AGENTS.md .github/copilot-instructions.md CHANGELOG.md

# 3. Verify nothing unexpected is staged
git status --short

# 4. Commit
git commit -m "docs: sync AGENTS.md and copilot-instructions with current source

$(git diff --staged --stat)

Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"

# 5. Push
git push
```

If `git push` fails due to branch protection, report the exact error and stop —
do not force-push or open a PR unless the user explicitly asks.

---

## Checklist before pushing

- [ ] Every stale constant/function/path value is corrected in both doc files
- [ ] No unrelated sections were modified
- [ ] CHANGELOG.md has an entry for each real change made
- [ ] `git diff --staged` shows only AGENTS.md, copilot-instructions.md, CHANGELOG.md
- [ ] Commit message is conventional-commits format (`docs: …`)

---

## Error handling

| Situation | Action |
|---|---|
| `grep` returns nothing for a constant | Warn: constant may have been renamed; show the user the grep and ask |
| A referenced function is gone | Flag as MISSING in the audit; update the doc to remove or replace it |
| CHANGELOG.md has no `[Unreleased]` section | Create one; do not modify versioned sections |
| `git push` fails | Report verbatim error; stop |
| Working tree is dirty before starting | Run `git status`; list unrelated changes; ask the user whether to stash or abort |
