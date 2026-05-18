# System Overview

## Repo Snapshot
PSNow is a PowerShell module that scaffolds new PowerShell modules via Plaster templates, then supports build, lint, test, package, and publish workflows.

## Languages and Formats
- PowerShell (`.ps1`, `.psm1`, `.psd1`) for runtime code, build orchestration, and tests.
- XML (`.xml`, `.nuspec`) for Plaster manifests, help, and package metadata.
- Markdown (`.md`) for docs and guides.
- YAML (`azure-pipelines.yml`) for CI pipeline config.

## Entry Points
- Runtime module loader: `PSNow.psm1`
	- Dot-sources all scripts in `Public/` and `Private/`.
	- Exports only functions from `Public/`.
- Main public command: `Public/New-PSNowModule.ps1`
	- Selects `Basic`, `Extended`, or `Advanced` template.
	- Copies selected Plaster manifest and invokes `Invoke-Plaster`.
- Supporting public command: `Public/Find-PSNowModule.ps1`
	- Reads and prints entries from `currentmodules.txt`.
- Build entry point: `Build/build.ps1`
	- Resolves dependencies, sets build environment variables, and dispatches PSake tasks.
- Task orchestration: `Build/build.psake.ps1`
	- Defines `Init`, `Stage`, `Analyze`, `Test`, `Help`, `BuildNuget`, `Publish*`, and combined tasks.

## Test Approach
- Framework: Pester.
- Test layout:
	- `tests/Unit/` for function-level behavior.
	- `tests/Common/` for shared helper behavior (for example environment helpers).
	- `tests/Integration/` for template/integration checks.
	- `tests/Acceptance/` for project-level validation.
- Execution path:
	- `Build/build.ps1 -TaskList test` runs Pester via `Build/build.psake.ps1`.
	- `Build/build.ps1 -TaskList analyze` runs PSScriptAnalyzer with `Build/PSScriptAnalyzerSettings.psd1`.

## Low-Risk Modules to Modify
1. `Public/Find-PSNowModule.ps1`
	 - Small, isolated behavior (read and print list from one file).
	 - Limited external side effects.

2. `Private/Get-PSNowEnvironmentVariables.ps1`
	 - Pure helper-style functions for OS/version/temp resolution.
	 - Good automated coverage in `tests/Common/Environment.tests.ps1`.

3. `Private/Write-PSNowScriptNoWhitespace.ps1`
	 - Narrow utility behavior focused on whitespace normalization.
	 - Does not change build orchestration logic or template manifests.

## Recommended Low-Risk Choice
Chosen module: `Private/Get-PSNowEnvironmentVariables.ps1`

Why this is low risk:
- Scope is tightly constrained to helper functions used for environment detection and temp path utilities.
- Changes can be validated quickly with existing targeted tests in `tests/Common/Environment.tests.ps1`.
- It avoids high-blast-radius surfaces such as template manifests, packaging tasks, and publish tasks.

## Exercise Notes
This overview now captures the repo mental model and the selected low-risk module for upcoming exercises.
