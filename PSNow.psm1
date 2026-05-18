$BHPathDivider = [System.IO.Path]::DirectorySeparatorChar

if (-not (Get-Module -Name 'Plaster' -ListAvailable)) {
    Write-Output "`nPlaster is not yet installed...installing Plaster now..."
    Install-Module -Name 'Plaster' -Scope 'CurrentUser' -Repository PSGALLERY -Force
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
