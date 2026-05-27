---
external help file: PSNow-help.xml
Module Name: psnow
online version:
schema: 2.0.0
---

# Find-PSNowModule

## SYNOPSIS
Finds your PSNow created modules

## SYNTAX

```
Find-PSNowModule [<CommonParameters>]
```

## DESCRIPTION
When you use PSNow to create a module, it adds the name and location to a file called Currentmodules.txt.
That list is returned to you here.

## EXAMPLES

### EXAMPLE 1
```
Find-PSNowModule
```

There are no parameters to add here, you're just getting a list of modules returned to you.

## PARAMETERS

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES

### Key File Paths

| Path | Purpose |
|---|---|
| `Public/Find-PSNowModule.ps1` | This function |
| `currentmodules.txt` | Append-only registry at the **module install root** (the directory containing `PSNow.psd1`). Each line is an absolute path to a module created by `New-PSNowModule`. |

### Behaviour When No Modules Exist

If `currentmodules.txt` does not exist at the expected path, `Find-PSNowModule`  
writes `"No modules have been created with PSNow yet."` and returns without error.

### Extension Guidance

`Find-PSNowModule` reads the same `currentmodules.txt` file that `New-PSNowModule`  
appends to. To extend the registry format:

1. Update `Public/New-PSNowModule.ps1` to write additional columns (e.g. CSV).
2. Update `Find-PSNowModule` to parse the new format.
3. Keep backward compatibility — existing single-path lines should still display.

### Risks

| Risk | Mitigation |
|---|---|
| `currentmodules.txt` paths become stale if a module is moved or deleted | `Find-PSNowModule` lists paths as-is; it does not validate that they still exist. Use `Test-Path` on each returned path to check. |
| Multiple PSNow installs writing to different `currentmodules.txt` files | The path is resolved relative to `$PSScriptRoot` of the installed module. Side-by-side installs each have their own registry file. |

## RELATED LINKS

- [`New-PSNowModule`](./New-PSNowModule.md)
- [`Public/Find-PSNowModule.ps1`](../Public/Find-PSNowModule.ps1)
