# Observability / Instrumentation

PSNow uses **structured logging** via `Write-PSNowStructuredLog` (which wraps `Write-Verbose`) to emit machine-parseable telemetry in the format:

```
[op=<operation>, status=<status>, field1=value1, field2=value2, ...]
```

## Instrumented Operations

| Operation | Status values | Key fields | Where |
|---|---|---|---|
| `invoke-plaster` | `started`, `retrying`, `completed`, `failed` | `elapsed_ms`, `module_name`, `manifest`, `destination`, `param_retries`, `removed_param` (retry only), `error` (failed only) | `New-PSNowModule` |
| `find-modules` | `completed` | `elapsed_ms`, `module_count`, `source` | `Find-PSNowModule` |

## Viewing Instrumentation Output

All structured logs are emitted via `Write-Verbose`. Enable them by running commands with `-Verbose`:

```powershell
# View Find-PSNowModule telemetry
Find-PSNowModule -Verbose

# Expected output (example):
# VERBOSE: [op=find-modules, status=completed, elapsed_ms=13, module_count=8, source=C:\localrepo\PSNow\currentmodules.txt]
```

```powershell
# View New-PSNowModule telemetry (including retry events if Plaster dynamic params change)
New-PSNowModule -NewModuleName 'TestMod' -BaseManifest 'Basic' -Verbose

# Expected output (example):
# VERBOSE: [op=invoke-plaster, status=started, elapsed_ms=0, module_name=TestMod, manifest=Basic, destination=c:\modules]
# VERBOSE: [op=invoke-plaster, status=retrying, retry=1, removed_param=SomeParam, module_name=TestMod, manifest=Basic]
# VERBOSE: [op=invoke-plaster, status=completed, elapsed_ms=1234, module_name=TestMod, manifest=Basic, destination=c:\modules, param_retries=1]
```

## Production / Staging

In CI/CD pipelines, structured logs are captured in the PowerShell verbose stream. Azure Pipelines, GitHub Actions, and similar CI systems automatically capture and index verbose output.

To aggregate logs in production:
1. Set `$VerbosePreference = 'Continue'` in your deployment script
2. Pipe output to a log aggregator (Splunk, ELK, Azure Monitor, etc.)
3. Parse the `[...]` format with regex: `\[(.+?)\]` → split on `, ` → parse `key=value` pairs

## Key Metrics to Monitor

| Metric | Query | Threshold |
|---|---|---|
| Module creation latency | `op=invoke-plaster AND status=completed` → avg(`elapsed_ms`) | p95 < 5000ms |
| Parameter retry rate | `op=invoke-plaster AND status=retrying` → count / total invocations | < 5% |
| Module discovery time | `op=find-modules AND status=completed` → avg(`elapsed_ms`) | p95 < 100ms |

## Adding New Instrumentation

Use the existing `Write-PSNowStructuredLog` helper:

```powershell
$sw = [System.Diagnostics.Stopwatch]::StartNew()
# ... do work ...
$sw.Stop()

Write-PSNowStructuredLog -Operation 'my-operation' -Status 'completed' -Fields ([ordered]@{
    elapsed_ms = $sw.ElapsedMilliseconds
    custom_field = $someValue
})
```

See `Private/Write-PSNowStructuredLog.ps1` for implementation details.
