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

    if (Test-Path $upperManifest -PathType Leaf) {
        Remove-Item -Path $upperManifest
    }

    # Use the canonical filename expected by Plaster on case-sensitive file systems.
    if (Test-Path $lowerManifest -PathType Leaf) {
        Remove-Item -Path $lowerManifest
    }

    # Direct path construction avoids Get-ChildItem + pipeline overhead for a known filename.
    $plasterdoc = Join-Path -Path $TemplateRoot -ChildPath "PlasterTemplate\$BaseManifest.xml"
    if (-not (Test-Path $plasterdoc -PathType Leaf)) {
        throw "Plaster manifest not found: $plasterdoc"
    }
    Copy-Item -Path $plasterdoc -Destination $lowerManifest
}
