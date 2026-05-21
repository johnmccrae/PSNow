# PSNow Architecture Map

This document maps conceptual components to concrete files in this repository.

## Entry Points

- PowerShell module entry point: `PSNow.psm1`
- Build entry point: `Build/build.ps1`
- CI entry point: `azure-pipelines.yml`
- Diagram validation entry point: `scripts/validate-architecture.ps1`

## Key Modules and Paths

| Conceptual node | Purpose | Real file path |
|---|---|---|
| Module loader | Dot-sources `Public/` and `Private/`, exports public functions | `PSNow.psm1` |
| Public command: `New-PSNowModule` | Creates a module scaffold via Plaster | `Public/New-PSNowModule.ps1` |
| Public command: `Find-PSNowModule` | Lists generated modules from tracker file | `Public/Find-PSNowModule.ps1` |
| Environment helpers | OS and temp-path helpers consumed by public commands | `Private/Get-PSNowEnvironmentVariables.ps1` |
| Template manifests | Manifest variants consumed by Plaster | `PlasterTemplate/Basic.xml`, `PlasterTemplate/Extended.xml`, `PlasterTemplate/Advanced.xml` |
| Build orchestration | Dependency resolution and PSake invocation | `Build/build.ps1` |
| Build tasks | Stage, analyze, test, publish tasks | `Build/build.psake.ps1` |
| Validation script | Runs init/stage/analyze/test locally | `scripts/validate.ps1` |
| Architecture diagram source | Mermaid source for architecture | `ai-track-docs/architecture.mmd` |

## Dependency Flow

1. `PSNow.psm1` imports scripts from `Public/*.ps1` and `Private/*.ps1`.
2. `Public/New-PSNowModule.ps1` depends on `Private/Get-PSNowEnvironmentVariables.ps1` and templates in `PlasterTemplate/*.xml`.
3. `Build/build.ps1` invokes PSake tasks from `Build/build.psake.ps1`.
4. `azure-pipelines.yml` invokes `Build/build.ps1` and the architecture validation script.

## Data Flow

1. User runs `New-PSNowModule`.
2. `New-PSNowModule` selects a base template (`Basic|Extended|Advanced`) and calls `Invoke-Plaster`.
3. Plaster outputs generated module files at `<ModuleRoot>/<NewModuleName>/...`.
4. `New-PSNowModule` appends the created module path to `currentmodules.txt`.
5. `Find-PSNowModule` reads `currentmodules.txt` and returns tracked module paths.

## Diagram

Primary source: `ai-track-docs/architecture.mmd`

The diagram includes:
- conceptual nodes mapped to real file paths
- dependency flow edges
- data flow edges
