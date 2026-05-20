# Dependencies & Pinning Policy

This document outlines PSNow's critical dependencies, version constraints, and the rationale for pinning decisions.

## Runtime Dependencies

### Plaster (Critical)

- **Module**: Plaster
- **Current version in build**: 1.1.3
- **Reason**: Plaster is the core templating engine for `New-PSNowModule`.
- **Constraint**: Pinned to 1.1.3. New releases should be tested before adoption; breaking changes in template manifests could break scaffolding.
- **Policy**: Bump only after validating all three templates (Basic, Extended, Advanced) produce valid modules and tests pass.

### No Runtime RequiredModules

PSNow itself does not declare `RequiredModules` in its manifest (`PSNow.psd1`). The module uses only built-in cmdlets and does not have hard runtime dependencies on external modules.

## Build-Time Dependencies

All pinned in `Build/build.depend.psd1`:

| Module | Version | Reason |
|--------|---------|--------|
| BuildHelpers | 2.0.16 | Sets up build environment variables; used by all tasks. |
| Plaster | 1.1.3 | Template engine for `New-PSNowModule`. |
| Pester | 5.7.1 | Test framework; all tests depend on this. |
| Microsoft.PowerShell.PlatyPS | 1.0.1 | Help generation for Advanced template modules. |
| PSake | 4.9.0 | Build orchestration; drives all build tasks. |
| PSDeploy | 1.0.5 | Deployment helper (optional; only used if deploy tasks are run). |
| PSScriptAnalyzer | 1.25.0 | Linting; analyze task depends on this. |
| posh-git | 1.1.0 | Git integration for build feedback. |

## PowerShell Version Constraints

- **Minimum**: PowerShell 5.0 (set in scaffolded modules via Plaster parameter).
- **Tested**: PowerShell 5.1 (Windows), PowerShell 7.x (cross-platform).
- **Rationale**: Plaster and Pester support this range; cross-platform support requires v6+.

## Pinning Policy

1. **Build dependencies are pinned** in `Build/build.depend.psd1` to tested versions.
2. **Rationale**: Build tools directly control output quality; uncontrolled upgrades risk breaking the build or test suite.
3. **When to bump**:
   - Security fixes: bump immediately and validate locally.
   - Feature additions: bump after manual testing (e.g., run full test suite and generate a sample module).
   - Major versions: bump in a feature branch, validate thoroughly, then merge.
4. **When NOT to bump**: Never bump build deps in a hotfix branch without testing.

## Scaffolded Module Dependencies

Modules created by PSNow inherit a recommended build/test stack:

- **Extended & Advanced templates** include:
  - Pester 5.0.0 minimum
  - PSScriptAnalyzer
  - PlatyPS (Advanced only)
  - BuildHelpers
  - PSake 4.8.0 minimum

These are set in the Plaster templates and documented in generated `Build/build.depend.psd1` files.

## Gap Analysis

| Area | Current | Gap | Notes |
|------|---------|-----|-------|
| Runtime version constraints | PSNow.psd1 has none | No hard constraint | Consider adding `PowerShellVersion = '5.0'` to PSNow.psd1 for clarity. |
| Transitive dependency tracking | Manual tracking | Not automated | If any build dep has breaking changes, we may miss them. Monitor release notes. |
| Dependency upgrades CI | Not implemented | No automated checks | PR validation could run with min and max supported versions. |

## Next Steps (Optional)

1. Add explicit `PowerShellVersion = '5.0'` to PSNow.psd1 manifest for documentation.
2. Consider adding a minimal integration test that runs the generated modules' build tasks to catch Plaster/PSake incompatibilities early.
3. Review build deps quarterly for security updates.
