---
external help file: PSNow-help.xml
Module Name: psnow
online version:
schema: 2.0.0
---

# New-PSNowModule

## SYNOPSIS
A module used to create new PS Modules with.

## SYNTAX

```
New-PSNowModule [-NewModuleName] <String> [-BaseManifest] <String> [[-ModuleRoot] <String>]
 [<CommonParameters>]
```

## DESCRIPTION
This module uses Plaster to create all the essential parts of a PowerShell Module.
It runs on PSCore and all supported platforms.

## EXAMPLES

## Safe Mode Toggle

You can control whether the module path output is shown after creation using the environment variable `PSNOW_SAFE_MODE`.

- If `PSNOW_SAFE_MODE` is set to a truthy value (`1`, `true`, `yes`, or `on`), the output message with the module path is suppressed.
- If it is not set, or set to a non-truthy value (for example `0`), the output message is shown as normal.

This is a simple safety toggle to reduce risk in automation or scripting scenarios.

### EXAMPLE 1
```
New-PSNowModule -NewModuleName "MyFabModule" -BaseManifest basic
```

Creates the new PS Module using the "basic" plaster mainfest which creates a minimal module for you

### EXAMPLE 2
```
New-PSNowModule -NewModuleName "MyFabModule" -BaseManifest Extended -ModuleRoot ~/modules/myfabmodule
```

This choice uses the Extended manifest and create the module in /modules.
Note that the module and pathing work for all versions of PS Core and PS Windows - Linux and OSX are supported platforms

### EXAMPLE 3
```
New-PSNowModule -NewModuleName "MyFabModule" -BaseManifest Advanced -ModuleRoot c:\myfabmodule
```

This choice creates a fully fleshed out PowerShell module with full support for Pester, Git, PlatyPS and more.
See the Advanced.xml file located in /PlasterTemplate

### Resilience — Plaster Parameter Stripping

`New-PSNowModule` delegates Plaster invocation to the private helper  
`Private/Invoke-PSNowPlasterSafely.ps1`.

When `Invoke-Plaster` raises a `ParameterBindingException` for an unrecognised  
parameter (e.g. a template-specific dynamic parameter that the selected manifest  
does not declare), the helper:

1. Extracts the offending parameter name from the exception message.  
2. Removes it from the splat.  
3. Retries `Invoke-Plaster` with the reduced parameter set.  
4. Repeats until the call succeeds or until no further named parameter can be  
   stripped — at which point the exception is rethrown.

There is **no fixed retry cap** and **no backoff delay**.  
This mechanism handles only `ParameterBindingException`; all other exception  
types are rethrown immediately.

> **Note:** File-system operations (e.g. creating `$ModuleRoot`) do **not** have  
> a retry wrapper. Only Plaster invocation is protected.

#### Example
```powershell
New-PSNowModule -NewModuleName "MyModule" -BaseManifest "Advanced"
```

## PARAMETERS

### -NewModuleName
The name you wish to give your new module

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -BaseManifest
You are selecting from 3 Plaster manifests located in the /PlasterTemplate directory - Advanced is the best choice

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ModuleRoot
Where do you want your new module to live?
The default is to put it in a /Modules folder off your drive root

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES

### Structured Logging

Every call to `Invoke-Plaster` is bracketed by two structured log entries written  
by `Private/Write-PSNowStructuredLog.ps1`:

| Event | Fields logged |
|---|---|
| `invoke-plaster / started` | `module_name`, `manifest`, `destination`, `elapsed_ms = 0` |
| `invoke-plaster / completed` | same fields plus actual `elapsed_ms` |
| `invoke-plaster / failed` | same fields plus `error` (exception message) |

Log output goes to the PowerShell information stream (visible with `-Verbose`).

### Key File Paths

| Path | Purpose |
|---|---|
| `Public/New-PSNowModule.ps1` | This function |
| `Private/Invoke-PSNowPlasterSafely.ps1` | Plaster invocation + parameter-stripping retry |
| `Private/Write-PSNowStructuredLog.ps1` | Structured log emitter |
| `Private/Remove-OldPSNowManifest.ps1` | Cleans up stale `PlasterManifest.xml` before each run |
| `PlasterTemplate/Basic.xml` | Minimal module scaffold |
| `PlasterTemplate/Extended.xml` | Module with tests and build helpers |
| `PlasterTemplate/Advanced.xml` | Full module with Pester, PlatyPS, Git support |
| `currentmodules.txt` | Append-only registry of created module paths (repo root) |

### Environment Variables

| Variable | Effect |
|---|---|
| `PSNOW_SAFE_MODE` | Set to `1`, `true`, `yes`, or `on` to suppress the output path message |
| `BHGitHubUser` | Passed to Plaster as `GitHubUserName`; set in your PowerShell profile |

### Extension Guidance

**Adding a new Plaster manifest:**

1. Create `PlasterTemplate/<Name>.xml` following the Plaster schema.
2. Add `"<Name>"` to the `[ValidateSet]` on `-BaseManifest` in  
   `Public/New-PSNowModule.ps1`.
3. Add a test case in `tests/Integration/` that calls  
   `New-PSNowModule -BaseManifest <Name>` against a temp directory.
4. Run `./Build/Build.ps1 -TaskList stage,analyze,test` to validate.

**Adding a new parameter to pass through to Plaster:**

Add the key/value pair to the `$PlasterParams` hashtable in `New-PSNowModule.ps1`.  
If the selected manifest does not declare the parameter, `Invoke-PSNowPlasterSafely`  
will silently strip it on the first `ParameterBindingException` and retry — no  
additional guard code is needed.

### Risks

| Risk | Mitigation |
|---|---|
| `PSNOW_SAFE_MODE` set unexpectedly in CI | The path output is suppressed but the module is still created normally. CI should not depend on the output message. |
| `BHGitHubUser` not set | `GitHubUserName` will be `$null`; Plaster strips it via the retry mechanism. The generated module will have no GitHub user pre-filled. |
| `currentmodules.txt` growing without bound | `Add-Content` appends one line per call. Prune manually or via `Find-PSNowModule` review. |
| Wrong `$ModuleRoot` path on Linux | Paths default to `~/modules` on non-Windows. Ensure the `~` expansion resolves correctly under the CI agent user. |

## RELATED LINKS

- [`Find-PSNowModule`](./Find-PSNowModule.md)
- [`Private/Invoke-PSNowPlasterSafely.ps1`](../Private/Invoke-PSNowPlasterSafely.ps1)
- [`PlasterTemplate/`](../PlasterTemplate/)
