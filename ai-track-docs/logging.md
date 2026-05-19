# Logging & Diagnostics

This document explains how to view the structured verbose logs emitted during the `Invoke-Plaster` portion of `New-PSNowModule`.

## Structured Log Format

The current implementation logs one important path: the `invoke-plaster` operation inside `New-PSNowModule`.

Each entry includes these core fields:

- **op**: Operation name. Current value: `invoke-plaster`.
- **status**: Operation state: `started`, `completed`, or `failed`.
- **elapsed_ms**: Elapsed time in milliseconds. The `started` entry uses `0`.

Additional fields provide context for the operation:

- **module_name**: Module being created.
- **manifest**: Selected Plaster manifest.
- **destination**: Destination path passed to Plaster.
- **error**: Error message when the operation fails.

### Example Log Entries

```text
[op=invoke-plaster, status=started, elapsed_ms=0, module_name=MyModule, manifest=Advanced, destination=c:\modules]
[op=invoke-plaster, status=completed, elapsed_ms=4230, module_name=MyModule, manifest=Advanced, destination=c:\modules]
```

## Viewing Logs

Structured logs are emitted through PowerShell's verbose stream.

### Show logs in the console

```powershell
New-PSNowModule -NewModuleName "MyModule" -BaseManifest "Advanced" -Verbose
```

You can also enable verbose output for the whole session:

```powershell
$VerbosePreference = 'Continue'
New-PSNowModule -NewModuleName "MyModule" -BaseManifest "Advanced"
```

### Capture logs to a file

Windows:

```powershell
New-PSNowModule -NewModuleName "MyModule" -BaseManifest "Advanced" -Verbose 4> "c:\logs\psnow-verbose.log"
```

macOS / Linux:

```powershell
New-PSNowModule -NewModuleName "MyModule" -BaseManifest "Advanced" -Verbose 4> "/tmp/psnow-verbose.log"
```

### Filter only the structured entries

```powershell
$VerbosePreference = 'Continue'
$logs = New-PSNowModule -NewModuleName "TestModule" -BaseManifest "Basic" 4>&1 |
    Where-Object { $_ -match '^\[op=invoke-plaster, status=' }

$logs | ForEach-Object { $_ }
```

## Troubleshooting with Logs

If `elapsed_ms` is unexpectedly high for `invoke-plaster`, check destination disk performance and whether antivirus or endpoint scanning is slowing file creation.

If no structured entries appear, confirm that verbose output is enabled with `-Verbose` or `$VerbosePreference = 'Continue'`.
