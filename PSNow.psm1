$PVersionNumber = $((Get-Variable 'PSVersionTable' -ValueOnly).PSVersion.Major)

if ($PVersionNumber -lt 6) {
    $BHPathDivider = "\"
}
elseif (Get-Variable -Name 'IsWindows' -ErrorAction 'SilentlyContinue' -ValueOnly ) {
    $BHPathDivider = "\"
}
elseif (Get-Variable -Name 'IsMacOS' -ErrorAction 'SilentlyContinue' -ValueOnly ) {
    $BHPathDivider = "/"
}
elseif (Get-Variable -Name 'IsLinux' -ErrorAction 'SilentlyContinue' -ValueOnly ) {
    $BHPathDivider = "/"
}


if (-not (Get-Module -Name 'Plaster' -ListAvailable)) {
    Write-Output "`nPlaster is not yet installed...installing Plaster now..."
    Install-Module -Name 'Plaster' -Scope 'CurrentUser' -Force
}

if (-not (Test-Path -path .gitignore)){
    New-Item -ItemType File -Name ".gitignore"
    Add-Content -Path $($PSScriptRoot + $BHPathDivider + ".gitignore") -Value ".vscode/"
    Add-Content -Path $($PSScriptRoot + $BHPathDivider + ".gitignore") -Value ".github/"
}

$Public = @( Get-ChildItem -Path $($PSScriptRoot + $BHPathDivider + "Public" + $BHPathDivider + "*.ps1") -ErrorAction SilentlyContinue )
$Private = @( Get-ChildItem -Path $($PSScriptRoot + $BHPathDivider + "Private" + $BHPathDivider + "*.ps1") -ErrorAction SilentlyContinue )

#Dot source the files
Foreach ($import in @($Public + $Private)) {
    Try {
        . $import.fullname
    }
    Catch {
        Write-Error -Message "Failed to import function $($import.fullname): $_"
    }
}

Export-ModuleMember -Function $Public.Basename
