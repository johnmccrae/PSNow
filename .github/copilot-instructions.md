# PSNow Copilot Instructions

## What This Project Is

PSNow is a PowerShell scaffolding module that generates new PS modules using Plaster templates. Its primary exported function, `New-PSNowModule`, invokes Plaster with one of three template manifests (`Basic`, `Extended`, `Advanced`) to produce a fully structured module at a user-specified destination path.

## Build & Test Commands

All build tasks are driven through PSake via a single entry point. Run from the repo root:

```powershell
# Install dependencies (first-time setup)
./Build/Build.ps1 -ResolveDependency

# Init / show build environment variables
./Build/Build.ps1 -TaskList init

# Run Pester tests
./Build/Build.ps1 -TaskList test

# Run PSScriptAnalyzer (lint)
./Build/Build.ps1 -TaskList analyze

# Lint + test together
./Build/Build.ps1 -TaskList analyze,test

# Stage module files (copies to /Staging/<ProjectName>)
./Build/Build.ps1 -TaskList stage
```

**Run a single Pester test file directly** (after staging):
```powershell
Invoke-Pester -Script ./tests/Unit/New-PSNowModule.tests.ps1
```

Tests require `BHModulePath` and `BHProjectName` env vars set by `Set-BuildEnvironment` (from BuildHelpers). Running via `build.ps1` sets these automatically.

## Architecture

### Module Loading (`PSNow.psm1`)

The root `.psm1` dot-sources every `.ps1` file in `Public/` and `Private/` at import time, then exports only the `Public/` basenames. Adding a new public function = drop a `.ps1` into `Public/`; it auto-exports.

### Build Pipeline (`Build/build.psake.ps1`)

PSake tasks form a dependency chain. The two full-pipeline composites are:
- `FullAzure`: Init → UpdateBuildVersion → ImportStagingModule → Stage → Help → Test → UpdateRepo → PublishAzure
- `FullPSGallery`: same chain ending in PublishPSGallery

The `Stage` task preserves the directory structure (Public/Private/etc.) under `Staging/<ProjectName>/`. The `CombineFunctionsAndStage` task instead merges all functions into a single `.psm1`.

### Plaster Templates (`PlasterTemplate/`)

Three XML manifests (`Basic.xml`, `Extended.xml`, `Advanced.xml`) define what `New-PSNowModule` produces. `New-PSNowModule` copies the selected manifest to the root as `PlasterManifest.xml`, then calls `Invoke-Plaster` with the repo root as `TemplatePath`.

### Environment Variables

Build uses `BH*`-prefixed env vars set by BuildHelpers' `Set-BuildEnvironment`. Additional custom vars are set in `build.ps1`:

| Variable | Purpose |
|---|---|
| `BHPathDivider` | OS path separator (`\` or `/`) |
| `BHBuildOS` | `Windows`, `macOS`, or `Linux` |
| `BHTempDirectory` | OS temp path |
| `BHBuildNumber` | Current module version from manifest |
| `BHBuildRevision` | Which version component to bump (`Major`/`Minor`/`Build`/`Revision`) |
| `BHCommitMessage` | Git commit message for `UpdateRepo` task |
| `BHGitHubUser` | Used as Plaster parameter `GitHubUserName` |
| `BHPSGalleryKey` | Required for `PublishPSGallery` task |
| `BHAzureBuildUser/Password/RepoUrl` | Required for `PublishAzure` task |

Set these in your PowerShell profile before working with build tasks.

## Key Conventions

### Private vs Public split

- **`Public/`** — one file per exported function, filename = function name (e.g., `New-PSNowModule.ps1`)
- **`Private/`** — internal helpers not exported; functions use a `PSNow` noun prefix (e.g., `GetPSNowOs`, `Get-PSNowTempDirectory`)

Private OS-detection helpers (`GetPSNowOs`, `GetPSNowPsVersion` in `Get-PSNowEnvironmentVariables.ps1`) use the indirection pattern so they can be mocked in Pester tests.

### Tests layout

- `tests/Unit/` — Pester unit tests; file naming: `<FunctionName>.tests.ps1`
- `tests/Acceptance/` — `Project.Tests.ps1` runs PSScriptAnalyzer rules + parse checks against staged files
- `Spec/` — Gherkin DSL feature specs (`psnow.feature` + `psnow.steps.ps1`); these `.ps1` files are **renamed to `.hold`** during the test task to prevent PSScriptAnalyzer from linting them

### PSScriptAnalyzer settings

Config is at `Build/PSScriptAnalyzerSettings.psd1`. Only `Warning` and `Error` severities are checked. `PSAvoidGlobalVars` is excluded. The build fails on `Error` severity. `Given`/`Then`/`When` are whitelisted as cmdlet aliases (Gherkin keywords).

### Version bumping

Pass `-Parameters @{BuildRev='Revision'}` (or `Major`/`Minor`/`Build`) to any task that needs a version bump. Without it, Build/Publish tasks default to `None` (no change).

### Cross-platform paths

Never hardcode path separators. Use `$env:BHPathDivider` (set at build time) or `[System.IO.Path]::DirectorySeparatorChar` for path construction throughout the module and build scripts.
