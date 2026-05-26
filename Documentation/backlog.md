# Backlog — Test & CI Infrastructure Hardening

Milestone: [Test & CI Infrastructure Hardening](https://github.com/johnmccrae/PSNow/milestone/1)

Items identified during Walk exercises ex1–ex11.

| # | Issue | Priority | Depends on |
|---|-------|----------|------------|
| [#29](https://github.com/johnmccrae/PSNow/issues/29) | Add YAML lint step to CI pipeline | High | — |
| [#30](https://github.com/johnmccrae/PSNow/issues/30) | Improve coverage reporting: separate unit vs integration test runs | Medium | — |
| [#31](https://github.com/johnmccrae/PSNow/issues/31) | Complete Pester 4 → 5 migration audit across all test files | Medium | — |
| [#32](https://github.com/johnmccrae/PSNow/issues/32) | Pin gitleaks version as a single pipeline variable | Low | — |
| [#33](https://github.com/johnmccrae/PSNow/issues/33) | Add CONTRIBUTING.md | Medium | #28 (PR template) |

## Item summaries

### #29 — Add YAML lint step to CI pipeline
A YAML formatting error in `azure-pipelines.yml` caused total pipeline failure (ex8–ex9). A lint step placed before all build tasks catches this before it reaches Azure DevOps.
**Code paths:** `azure-pipelines.yml`

### #30 — Improve coverage reporting
`Write-CoverageSummary.ps1` runs all tests; unit tests use heavy mocking, which contributes 0 executed commands. A `-TestType` parameter (`Unit` | `Integration` | `All`) would allow targeted runs.
**Code paths:** `scripts/Write-CoverageSummary.ps1`, `tests/Unit/`, `tests/Integration/`

### #31 — Complete Pester 4 → 5 migration audit
`Environment.tests.ps1` was fixed in ex10 but a full audit of all 15 test files was never completed. Any remaining Pester 4 patterns risk silent failures.
**Code paths:** `tests/Unit/*.tests.ps1`, `tests/Common/*.tests.ps1`, `tests/Acceptance/`, `tests/Integration/`

### #32 — Pin gitleaks version as a pipeline variable
Version `8.30.1` is hardcoded in two places in `azure-pipelines.yml`. Extracting it to a single variable prevents drift when upgrading.
**Code paths:** `azure-pipelines.yml` (Windows install ~line 18, Linux install ~line 30)

### #33 — Add CONTRIBUTING.md
No contributor documentation exists. New contributors must infer build workflow, branch strategy, and PR process from the code. Blocked by #28 (PR template).
**Code paths:** `Build/build.psake.ps1`, `.github/pull_request_template.md`, `README.md`
