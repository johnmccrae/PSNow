# Performance Baseline

Date: 2026-05-18
Branch: ex6
Function measured: `Find-PSNowModule`

## Benchmark Command

```powershell
Import-Module ./PSNow.psd1 -Force
$runs = 12
$iterations = 2000
$samples = for ($r=1; $r -le $runs; $r++) {
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    for ($i=0; $i -lt $iterations; $i++) {
        $null = Find-PSNowModule | Out-Null
    }
    $sw.Stop()
    [pscustomobject]@{
        Run       = $r
        TotalMs   = [math]::Round($sw.Elapsed.TotalMilliseconds, 3)
        PerCallUs = [math]::Round(($sw.Elapsed.TotalMilliseconds * 1000.0) / $iterations, 3)
    }
}
$stats = $samples | Measure-Object -Property PerCallUs -Average -Minimum -Maximum -StandardDeviation
```

## Baseline Results

- Runs: 12
- Iterations per run: 2000
- Average: 483.552 us per call
- Min: 465.942 us per call
- Max: 501.405 us per call
- StdDev: 12.399 us

## Per-Run Samples (us/call)

- Run 1: 492.770
- Run 2: 465.940
- Run 3: 467.540
- Run 4: 467.090
- Run 5: 489.040
- Run 6: 472.950
- Run 7: 482.340
- Run 8: 494.580
- Run 9: 485.470
- Run 10: 501.400
- Run 11: 486.960
- Run 12: 496.540

## Variance Notes

- Spread was modest in this run (`min` to `max` span about 35.463 us).
- Standard deviation was 12.399 us, indicating relatively tight clustering around the mean.
- No optimization changes were made as part of this exercise; this file is measurement-only.
