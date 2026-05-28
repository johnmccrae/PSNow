# PSNow Operations Runbook — Resilience Patterns

## Overview

PSNow uses an exponential-backoff retry helper (`Invoke-PSNowWithRetry`) to
protect three I/O call paths against transient failures (file locks, disk
contention, network-mounted filesystems).

---

## Protected Call Paths

| Call path | Function | OperationName | Default MaxAttempts | Default InitialDelayMs |
|---|---|---|---|---|
| `Copy-Item` (manifest copy) | `Remove-OldPSNowManifest` | `manifest-copy` | 3 | 200 ms |
| `Add-Content` (tracker append) | `New-PSNowModule` | `tracker-append` | 3 | 100 ms |
| `Get-Content` (tracker read) | `Find-PSNowModule` | `tracker-read` | 3 | 100 ms |

---

## Helper Signature

```powershell
Invoke-PSNowWithRetry
    -ScriptBlock      <scriptblock>   # .GetNewClosure() recommended at call site
    [-MaxAttempts     <int>]          # default 3
    [-InitialDelayMs  <int>]          # default 500 ms
    [-BackoffMultiplier <double>]     # default 2.0 (doubles each retry)
    [-TimeoutSeconds  <double>]       # default 0 (no limit)
    [-OperationName   <string>]       # label for structured log entries
```

### Delay schedule (defaults)

| Attempt | Delay before next retry |
|---|---|
| 1 | 500 ms |
| 2 | 1 000 ms |
| 3 | 2 000 ms |
| … | × BackoffMultiplier each time |

---

## Tuning Parameters

### Increase resilience on slow/shared filesystems

```powershell
Invoke-PSNowWithRetry -MaxAttempts 5 -InitialDelayMs 1000 -BackoffMultiplier 2.0 -ScriptBlock { ... }.GetNewClosure()
```

### Add a total-elapsed timeout cap

```powershell
# Give up entirely if 30 seconds have elapsed across all retries.
Invoke-PSNowWithRetry -TimeoutSeconds 30 -MaxAttempts 10 -ScriptBlock { ... }.GetNewClosure()
```

### Reduce aggressiveness on fast local disks

```powershell
Invoke-PSNowWithRetry -MaxAttempts 2 -InitialDelayMs 50 -BackoffMultiplier 1.5 -ScriptBlock { ... }.GetNewClosure()
```

---

## Structured Log Entries

Every transition emits a `Write-PSNowStructuredLog` entry. Use these to
diagnose retry storms in CI output.

| Status | Meaning |
|---|---|
| `attempt` | Operation is about to be attempted (fields: `attempt`, `max_attempts`) |
| `completed` | Attempt succeeded (fields: `attempt`, `elapsed_ms`) |
| `error` | Attempt failed, will retry (fields: `attempt`, `error`) |
| `retry` | Sleeping before next attempt (fields: `attempt`, `delay_ms`) |
| `failed` | All attempts exhausted, exception re-thrown (fields: `attempts`, `elapsed_ms`) |
| `timeout` | Elapsed time exceeded `TimeoutSeconds` (fields: `elapsed_s`, `timeout_s`, `attempts`) |

---

## Escalation Steps

1. **Single failure, recovery logged** — no action needed; transient I/O issue resolved itself.
2. **Repeated `error → retry` in CI** — check for file-locking processes holding
   `PlasterManifest.xml` or `currentmodules.txt`. Increase `MaxAttempts` or `InitialDelayMs`.
3. **`failed` logged** — the operation did not recover. Inspect the `error` field.
   Common causes: read-only filesystem, disk full, missing source file.
4. **`timeout` logged** — total time budget exhausted. Either the system is under
   severe load, or `TimeoutSeconds` is set too low for the filesystem latency.
   Increase `TimeoutSeconds` or investigate I/O bottleneck.

---

## Rollback

To remove the resilience wrapping and revert to direct I/O calls:

```powershell
git revert <sha>  # revert the Ex15 commit
```

Or manually restore the three call sites:

| File | Replace | With |
|---|---|---|
| `Private/Remove-OldPSNowManifest.ps1` | `Invoke-PSNowWithRetry -OperationName 'manifest-copy' …` block | `Copy-Item -Path $plasterdoc -Destination $lowerManifest` |
| `Public/New-PSNowModule.ps1` | `Invoke-PSNowWithRetry -OperationName 'tracker-append' …` block | `Add-Content -Path $doc -Value $Path` |
| `Public/Find-PSNowModule.ps1` | `$rawLines = Invoke-PSNowWithRetry …` block | `$modules = Get-Content -Path $thefile \| Where-Object { … }` |

And delete `Private/Invoke-PSNowWithRetry.ps1`.

The helper itself carries no persistent state; removing it leaves the module
in the same functional state as before Ex15.

---

## Current Failure Behavior (Before Ex15)

| Call path | Failure mode |
|---|---|
| `Copy-Item` (manifest copy) | Exception propagated immediately; `New-PSNowModule` aborts |
| `Add-Content` (tracker append) | Exception propagated; module is created but not tracked |
| `Get-Content` (tracker read) | Exception propagated; `Find-PSNowModule` returns nothing |
