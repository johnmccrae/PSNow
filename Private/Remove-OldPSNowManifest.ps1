function Remove-OldPSNowManifest {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "")]
    param (
        [Parameter(Mandatory = $true)]
        [string]$TemplateRoot,

        [Parameter(Mandatory = $true)]
        [string]$BaseManifest
    )

    $upperManifest = Join-Path -Path $TemplateRoot -ChildPath 'PlasterManifest.xml'
    $lowerManifest = Join-Path -Path $TemplateRoot -ChildPath 'plasterManifest.xml'

    Write-PSNowStructuredLog -Operation 'manifest-setup' -Status 'started' -Fields ([ordered]@{
        manifest = $BaseManifest
    })

    if (Test-Path $upperManifest -PathType Leaf) {
        Remove-Item -Path $upperManifest
        Write-PSNowStructuredLog -Operation 'manifest-setup' -Status 'removed' -Fields ([ordered]@{
            path = $upperManifest
        })
    }

    # Use the canonical filename expected by Plaster on case-sensitive file systems.
    if (Test-Path $lowerManifest -PathType Leaf) {
        Remove-Item -Path $lowerManifest
        Write-PSNowStructuredLog -Operation 'manifest-setup' -Status 'removed' -Fields ([ordered]@{
            path = $lowerManifest
        })
    }

    # Build the source path directly — the filename is always "$BaseManifest.xml" and
    # the directory is always PlasterTemplate/. This avoids a Get-ChildItem directory
    # scan on every New-PSNowModule call.
    $plasterdoc = Join-Path -Path $TemplateRoot -ChildPath 'PlasterTemplate' -AdditionalChildPath "$BaseManifest.xml"
    Invoke-PSNowWithRetry -OperationName 'manifest-copy' -MaxAttempts 3 -InitialDelayMs 200 `
        -ScriptBlock { param($src, $dst) Copy-Item -Path $src -Destination $dst } `
        -ArgumentList @($plasterdoc, $lowerManifest)

    Write-PSNowStructuredLog -Operation 'manifest-setup' -Status 'completed' -Fields ([ordered]@{
        manifest    = $BaseManifest
        destination = $lowerManifest
    })
}
