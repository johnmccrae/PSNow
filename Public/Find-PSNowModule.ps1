<#
.SYNOPSIS
Finds your PSNow created modules

.DESCRIPTION
When you use PSNow to create a module, it adds the name and location to a file called Currentmodules.txt. That list is returned to you here.

.EXAMPLE
Find-PSNowModule

There are no parameters to add here, you're just getting a list of modules returned to you.

.NOTES
General Notes

#>
function Find-PSNowModule {
    [CmdletBinding()]
    param (
    )

    begin {
        $ErrorActionPreference = 'Continue'
    }

    process{
        $sw = [System.Diagnostics.Stopwatch]::StartNew()
        $scriptPath = Split-Path $PSScriptRoot -Parent
        $thefile = Join-Path -Path $scriptPath -ChildPath "currentmodules.txt"

        if (-not (Test-Path -Path $thefile)) {
            $sw.Stop()
            Write-PSNowStructuredLog -Operation 'find-modules' -Status 'completed' -Fields ([ordered]@{
                elapsed_ms   = $sw.ElapsedMilliseconds
                module_count = 0
                source       = $thefile
            })
            Write-Output "No modules have been created with PSNow yet."
            return
        }

        # Wrap file read with retry: currentmodules.txt may be briefly locked
        # (e.g. antivirus scan, concurrent write) on first access.
        $modules = Invoke-PSNowWithRetry -Operation { Get-Content -Path $thefile } `
            -MaxRetries 3 -InitialDelayMs 200 `
            -RetryOnExceptionType @([System.IO.IOException], [System.UnauthorizedAccessException])
        $moduleCount = @($modules | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }).Count
        $sw.Stop()

        Write-PSNowStructuredLog -Operation 'find-modules' -Status 'completed' -Fields ([ordered]@{
            elapsed_ms   = $sw.ElapsedMilliseconds
            module_count = $moduleCount
            source       = $thefile
        })

        Write-Output "`n"
        Write-Output "Here's your list of PSNow Modules"
        Write-Output "---------------------------------"
        foreach($module in $modules){
            Write-Output $module
        }
        Write-Output "`n"

    }
}