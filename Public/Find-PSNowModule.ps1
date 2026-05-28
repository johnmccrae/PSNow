<#
.SYNOPSIS
Finds your PSNow created modules

.DESCRIPTION
When you use PSNow to create a module, it adds the name and location to a file called
Currentmodules.txt. That list is returned to you here.

Blank lines in the tracker file are silently filtered out. Use -Validate to flag
paths that no longer exist on disk.

.PARAMETER Validate
When specified, each listed path is tested for existence. Paths that no longer
exist on disk are marked with [STALE] in the output.

.EXAMPLE
Find-PSNowModule

Returns the list of all modules created with PSNow.

.EXAMPLE
Find-PSNowModule -Validate

Returns the list with [STALE] appended to any path that no longer exists on disk.

.NOTES
General Notes

#>
function Find-PSNowModule {
    [CmdletBinding()]
    [OutputType([string[]])]
    param (
        [Parameter()]
        [switch]$Validate
    )

    begin {
        $ErrorActionPreference = 'Continue'
    }

    process{
        $scriptPath = Split-Path $PSScriptRoot -Parent
        $thefile = Join-Path -Path $scriptPath -ChildPath "currentmodules.txt"

        Write-PSNowStructuredLog -Operation 'find-modules' -Status 'started' -Fields ([ordered]@{
            path = $thefile
        })

        if (-not (Test-Path -Path $thefile)) {
            Write-PSNowStructuredLog -Operation 'find-modules' -Status 'not-found' -Fields ([ordered]@{
                path = $thefile
            })
            Write-Output "No modules have been created with PSNow yet."
            return
        }

        # Blank lines accumulate when entries are appended across runs.
        # Filter them on read to keep output clean without modifying the file.
        $rawLines = Invoke-PSNowWithRetry -OperationName 'tracker-read' -MaxAttempts 3 -InitialDelayMs 100 `
            -ScriptBlock { param($filePath) Get-Content -Path $filePath } `
            -ArgumentList $thefile
        $modules = $rawLines | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }

        Write-PSNowStructuredLog -Operation 'find-modules' -Status 'completed' -Fields ([ordered]@{
            count = $modules.Count
            path  = $thefile
        })

        Write-Output "`n"
        Write-Output "Here's your list of PSNow Modules"
        Write-Output "---------------------------------"
        foreach ($module in $modules) {
            if ($Validate -and -not (Test-Path -Path $module -PathType Container)) {
                Write-Output "$module [STALE]"
            }
            else {
                Write-Output $module
            }
        }
        Write-Output "`n"

    }
}
