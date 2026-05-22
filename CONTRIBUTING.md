# Contributing to PSNow

Thank you for contributing! This document covers the branching strategy, PR expectations, and how to work with GitHub Copilot on this project.

---

## Table of Contents

- [Prerequisites](#prerequisites)
- [Branching Strategy](#branching-strategy)
- [Development Workflow](#development-workflow)
- [PR Expectations](#pr-expectations)
- [Using GitHub Copilot](#using-github-copilot)
- [Walk Track Workflow](#walk-track-workflow)
- [Validation](#validation)
- [Code Conventions](#code-conventions)

---

## Prerequisites

1. **PowerShell 7+** — all scripts target PS Core.
2. **Required modules** — install once from the repo root:
   ```powershell
   ./Build/Build.ps1 -ResolveDependency
   ```
3. **Environment variables** — add to your PowerShell profile:
   ```powershell
   Set-Item -Path Env:BHGitHubUser       -Value '<your GitHub username>'
   Set-Item -Path Env:BHPSGalleryKey     -Value '<PS Gallery key>'
   Set-Item -Path Env:BHAzureBuildUser   -Value '<Azure build user>'
   Set-Item -Path Env:BHAzureBuildPassword -Value '<Azure token>'
   Set-Item -Path Env:BHAzureRepoUrl     -Value '<Azure Artifacts feed URL>'
   ```

---

## Branching Strategy

| Branch pattern | Purpose |
|---|---|
| `main` | Stable, always green. PRs merge here. |
| `walk-ex<N>` | One branch per Walk-track exercise (e.g., `walk-ex3`) |
| `crawl-ex<N>` | One branch per Crawl-track exercise |
| `run-ex<N>` | One branch per Run-track exercise |

**Rules:**
- Branch from the tip of the previous exercise branch (or `main` after it merges).
- Keep branches small — one exercise, one PR.
- Never commit directly to `main`.

```powershell
git checkout main && git pull
git checkout -b walk-ex5
```

---

## Development Workflow

1. **Plan first** — identify the goal and list the files you will touch before writing any code.
2. **Make changes** — implement file by file; review each diff before moving on.
3. **Validate locally** — always run the full validate script before pushing:
   ```powershell
   ./scripts/validate.ps1
   ```
   Expected output: `Tests Passed: N, Failed: 0`.
4. **Commit with intent** — write a commit message that explains *what* and *why*.
5. **Open a PR** — use the PR template described below.

---

## PR Expectations

Every PR must include the following sections. Use the template below as your PR body:

```
## Summary
- What changed and why
- Plan: <inline summary or link>
- Files/paths touched

## Evidence
- Tests/logs/metrics: <commands + output summary>
- Coverage: <percentage or contract evidence>

## Risk & Rollback
- Risk: low/medium/high
- Rollback: revert <commit SHA> or toggle <flag>

## Review Focus
- Key areas for reviewer attention
- Verification steps the reviewer can run

## Track
- Level: Walk
- Exercise: ex<N>
```

**Evidence is mandatory.** Paste the test result line from `validate.ps1`:
```
Tests Passed: 266, Failed: 0, Skipped: 4
```

---

## Using GitHub Copilot

PSNow uses a **plan-first, evidence-backed** workflow with Copilot:

### Starting a task
1. Describe the goal to Copilot in plain English.
2. Ask Copilot to **write a plan** (files to change, reason, expected impact) before touching any code.
3. Review the plan. Ask Copilot to adjust scope if it touches more than 4 files.

### Reviewing diffs
- Ask Copilot to generate changes **file by file**.
- Review each diff before accepting — don't bulk-accept.
- If a change looks wrong, say so: "That will break X because Y. Try Z instead."

### After changes
- Run `./scripts/validate.ps1` and paste the output summary back to Copilot.
- If tests fail, share the failure output and ask Copilot to diagnose before reverting.

### Useful prompts
```
"Write a plan for [task]. List each file, the reason for changing it, and expected impact. Stay under 4 files."

"Generate the diff for [filename] only. I'll review before moving to the next file."

"The validate script failed with this error: [paste]. What caused it and how do I fix it?"
```

---

## Walk Track Workflow

The Walk track builds on Crawl by introducing plan-first development, evidence-backed PRs, and Copilot-assisted refactoring. Each exercise follows this cycle:

```
Plan → Implement → Validate → PR
```

### Exercise naming
- Branch: `walk-ex<N>`
- PR title: `GHCP -- Walk: ex<N> <short description>`

### What "plan-first" means
Before writing code, produce a short written plan that answers:
- What files will change?
- Why is each change needed?
- What is the expected impact (behaviour, tests, lines changed)?

Include this plan verbatim in the PR description under `## Summary`.

### Evidence requirements
- Run `./scripts/validate.ps1` — paste the `Tests Passed` line.
- For coverage exercises, run `./scripts/run-coverage.ps1` — paste the `Total coverage` line and attach `BuildOutput/coverage-summary.txt`.

### Keeping scope small
If a refactor touches more than 4 files, narrow it. The smallest meaningful change is always preferred over the most complete one.

---

## Validation

The single entry point for all local validation is:

```powershell
./scripts/validate.ps1
```

This runs (in order): dependency resolution → init → stage → PSScriptAnalyzer → Pester tests → architecture diagram render.

Individual tasks can also be run via the build system:

```powershell
./Build/build.ps1 -TaskList stage
./Build/build.ps1 -TaskList analyze
./Build/build.ps1 -TaskList test
./Build/build.ps1 -TaskList analyze,test
```

CI runs the same pipeline on both **Windows** and **Ubuntu** via Azure Pipelines (`azure-pipelines.yml`). A PR is not mergeable until both matrix legs are green.

---

## Code Conventions

See `.github/copilot-instructions.md` for the full reference. Key rules:

- **One file per function** in `Public/` and `Private/`.
- **Private helpers** use a `PSNow` noun prefix (e.g., `Get-PSNowTempDirectory`).
- **Paths** — always use `Join-Path`; never hardcode `\` or `/`.
- **PSScriptAnalyzer** — the build fails on `Error` severity. Add `SuppressMessageAttribute` only when the rule genuinely doesn't apply, and comment why.
- **Tests** — unit tests live in `tests/Unit/<FunctionName>.tests.ps1`. Add a test for every new public function.
