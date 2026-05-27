# Performance Baseline — Exercise 6
# Measured: 2026-05-27, Windows, PSNow repo

## Remove-OldPSNowManifest — template path lookup
Method                  | 1000 calls (ms) | Per call (ms)
------------------------|-----------------|---------------
BEFORE: Get-ChildItem   |     994 ms      |  0.994 ms
AFTER: Join-Path direct |      28 ms      |  0.028 ms
Improvement             |                 | 97.2%

## Write-PSNowStructuredLog — List vs array+=
FINDING (not implemented): List[string] approach showed 54% SLOWER for 4-6 items
because List::new() constructor overhead dominates at small collection sizes.
Reverted to original array+= approach. No change made.

## GetPSNowOs — module-scoped cache
FINDING (not implemented): Cache correctly eliminates repeated OS detection calls
but breaks Pester test isolation — cache populated in test N poisons test N+1 when
tests mock GetPSNowPsVersion. Would require BeforeEach {  =  }
in all affected test files. Reverted.

## Module import time (unchanged)
5 runs: 126, 90, 84, 85, 91 ms | Average: 95.2 ms
