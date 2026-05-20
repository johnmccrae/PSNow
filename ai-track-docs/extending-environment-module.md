# Extending the Environment Module

This note covers how to safely extend the environment helper logic in `Private/Get-PSNowEnvironmentVariables.ps1`.

## Scope

The module currently provides:
- `GetPSNowPsVersion`: returns PowerShell major version through `Get-Variable` for testability.
- `GetPSNowOs`: resolves `Windows`, `macOS`, or `Linux`.
- `Get-PSNowTempDirectory`: returns a platform temp directory (special-case for macOS).
- `Get-PSNowTempRegistry`: ensures and returns a Windows test registry path.

## Rules to Preserve

- Keep return values unchanged:
  - `GetPSNowOs` must return exactly `Windows`, `macOS`, or `Linux`.
  - Unknown platforms must throw `Unsupported Operating system!`.
- Keep OS check order in `GetPSNowOs`:
  1. `IsWindows`
  2. `IsMacOS`
  3. `IsLinux`
- Access platform flags via `Get-Variable` so tests can mock behavior.

## How to Add New Behavior

1. Add behavior in `Private/Get-PSNowEnvironmentVariables.ps1`.
2. Add or update tests in `tests/Common/Environment.tests.ps1`.
3. For branch-specific tests, explicitly mock earlier branch checks to `$false` so assertions are deterministic.
4. Run focused tests first:

```powershell
Import-Module ./PSNow.psd1 -Force
Invoke-Pester -Path ./tests/Common/Environment.tests.ps1 -Output Detailed
```

## Common Pitfalls

- Changing string outputs (for example `OSX` vs `macOS`) breaks existing expectations.
- Calling automatic variables directly (instead of `Get-Variable`) makes tests OS-dependent.
- Reordering OS checks can alter behavior and mock invocation counts.
