# Build and Test

Run commands from the repository root (`C:\localrepo\PSNow`).

## One-command validation (preferred)

For repeatable local validation, use the wrapper scripts:

```powershell
./scripts/validate.ps1
```

```sh
./scripts/validate.sh
```

Both scripts run the same steps in order:
1. `./Build/build.ps1 -ResolveDependency -TaskList init`
2. `./Build/build.ps1 -TaskList stage`
3. `./Build/build.ps1 -TaskList analyze`
4. `./Build/build.ps1 -TaskList test`

CI uses the same two commands in `azure-pipelines.yml`.

## First-time setup
```powershell
./Build/Build.ps1 -ResolveDependency
```

## Full validation path (repeatable)
```powershell
./Build/Build.ps1 -TaskList init
./Build/Build.ps1 -TaskList analyze
./Build/Build.ps1 -TaskList test
```

## Build environment
```powershell
./Build/Build.ps1 -TaskList init
```

## Test
```powershell
./Build/Build.ps1 -TaskList test
```

## Lint (PSScriptAnalyzer)
```powershell
./Build/Build.ps1 -TaskList analyze
```

## Lint + test
```powershell
./Build/build.ps1 -TaskList stage
./Build/build.ps1 -TaskList analyze
./Build/build.ps1 -TaskList test
```

## Stage output
```powershell
./Build/Build.ps1 -TaskList stage
```

## Run one deterministic test for chosen module
Chosen module: `Private/Get-PSNowEnvironmentVariables.ps1`

```powershell
Import-Module ./PSNow.psd1 -Force
Invoke-Pester -Path ./tests/Common/Environment.tests.ps1 -Tag Deterministic -Output Detailed
```

Deterministic assertion added:
- `GetPSNowOs` throws `Unsupported Operating system!` when all OS flags are false and version is mocked to 6.

This is a starter reference and will be refined in Exercise 2.
