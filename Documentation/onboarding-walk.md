# PSNow — Walk Track Onboarding Prompt

> **How to use this file:** Paste the contents of the "Copilot Chat Prompt" section below directly into a GitHub Copilot Chat window (or any Copilot-enabled IDE chat). It gives Copilot everything it needs to orient itself to the project and assist you with Walk-track exercises.

---

## Copilot Chat Prompt

```
You are helping me work on the PSNow repository (github.com/johnmccrae/PSNow).

## What PSNow is
PSNow is a PowerShell scaffolding module. Its primary exported function, New-PSNowModule,
invokes Plaster with one of three template manifests (Basic, Extended, Advanced) to generate
a fully structured PowerShell module at a user-specified destination path.

## Project layout
- Public/          — one .ps1 per exported function (auto-exported by PSNow.psm1)
- Private/         — internal helpers, not exported; use PSNow noun prefix
- tests/Unit/      — Pester unit tests, named <FunctionName>.tests.ps1
- tests/Acceptance/— PSScriptAnalyzer + parse checks run against Staging/
- tests/Common/    — shared tests (manifest, help, environment, basic)
- tests/Integration/— full Plaster invocation tests
- Build/           — PSake tasks (build.psake.ps1), dependency manifest, PSSA settings
- PlasterTemplate/ — Basic.xml, Extended.xml, Advanced.xml Plaster manifests
- scripts/         — helper scripts (validate.ps1, run-coverage.ps1, etc.)
- Documentation/   — function reference docs and onboarding guides (here)

## How to validate (always run before pushing)
./scripts/validate.ps1
# Expect: Tests Passed: N, Failed: 0, exit code 0

## How to run coverage
./scripts/run-coverage.ps1
# Expect: [coverage] Total coverage: N.NN%

## Individual build tasks
./Build/build.ps1 -TaskList stage        # stage module to Staging/PSNow/
./Build/build.ps1 -TaskList analyze      # run PSScriptAnalyzer
./Build/build.ps1 -TaskList test         # run Pester
./Build/build.ps1 -TaskList analyze,test # lint + test together

## CI
Azure Pipelines runs against Windows and Ubuntu. Both must be green for a PR to merge.
Config: azure-pipelines.yml

## Key conventions
- Always use Join-Path for path construction (never hardcode \ or /)
- PSScriptAnalyzer errors fail the build; suppress only when genuinely inapplicable
- Verbs that change state (New-, Set-, Remove-) need SuppressMessageAttribute or ShouldProcess
- Private helpers use indirection pattern (Get-Variable instead of $PSVersionTable) so they can be mocked

## Walk track workflow
I am working on the Walk track of the GitHub Copilot training curriculum.
Each exercise follows: Plan → Implement → Validate → PR.

Rules:
- Write a plan (files, reason, impact) BEFORE touching code
- Generate diffs file by file; I review each before accepting
- Never touch more than 4 files per exercise
- Every PR includes: plan, test evidence (paste from validate.ps1), risk, rollback

## Current exercise
[REPLACE THIS LINE with the exercise description before pasting]
```

---

## Quick Reference

### Branch and PR naming
```powershell
git checkout -b walk-ex<N>
# PR title: "GHCP -- Walk: ex<N> <short description>"
```

### Validate before every push
```powershell
./scripts/validate.ps1          # full pipeline
./scripts/run-coverage.ps1      # coverage report (writes BuildOutput/coverage-summary.txt)
```

### PR body sections (required)
| Section | What to include |
|---|---|
| **Summary** | What changed, why, files touched |
| **Evidence** | `Tests Passed: N, Failed: 0` from validate output |
| **Risk & Rollback** | Risk level + `git revert <SHA>` |
| **Review Focus** | What the reviewer should check + verification commands |
| **Track** | Level: Walk, Exercise: ex\<N\> |

### Common Copilot prompts for Walk exercises

**Starting a task:**
> "Write a plan for [goal]. List each file to change, the reason, and expected impact. Keep scope to 4 files or fewer."

**Reviewing a diff:**
> "Show me only the diff for [filename]. I'll review before moving to the next file."

**Diagnosing a failure:**
> "The validate script failed with this error: [paste output]. What caused it and how do I fix it without reverting?"

**Writing a PR:**
> "Write the PR body for this change using the PSNow PR template. Include the plan inline and the test evidence: Tests Passed: N, Failed: 0."

---

## Environment Setup

First-time setup — run once from the repo root:

```powershell
./Build/Build.ps1 -ResolveDependency
```

Profile variables (add to `$PROFILE`):

```powershell
Set-Item -Path Env:BHGitHubUser         -Value '<your GitHub username>'
Set-Item -Path Env:BHPSGalleryKey       -Value '<PS Gallery key>'
Set-Item -Path Env:BHAzureBuildUser     -Value '<Azure build user>'
Set-Item -Path Env:BHAzureBuildPassword -Value '<Azure token>'
Set-Item -Path Env:BHAzureRepoUrl       -Value '<Azure Artifacts feed URL>'
```

---

## Further Reading

- [`CONTRIBUTING.md`](../CONTRIBUTING.md) — full contribution guide
- [`.github/copilot-instructions.md`](../.github/copilot-instructions.md) — Copilot context file (architecture, conventions, build commands)
- [`ai-track-docs/SYSTEM-OVERVIEW.md`](../ai-track-docs/SYSTEM-OVERVIEW.md) — system architecture overview
- [`ai-track-docs/build-test.md`](../ai-track-docs/build-test.md) — build and test deep-dive
