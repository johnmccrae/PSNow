if (-not (Get-Module -Name 'Plaster' -ListAvailable)) {
    Write-Output "`nPlaster is not yet installed...installing Plaster now..."
    Install-Module -Name 'Plaster' -Scope 'CurrentUser' -Force
}
else {
    Write-Output "Module Plaster is already installed"
}

if (-not (Test-Path -path .gitignore)){
    New-Item -ItemType File -Name ".gitignore"
    Add-Content -Path "$PSScriptRoot\.gitignore" -Value ".vscode/"
    Add-Content -Path "$PSScriptRoot\.gitignore" -Value ".github/"
}


$Public = @( Get-ChildItem -Path $PSScriptRoot\Public\*.ps1 -ErrorAction SilentlyContinue )
$Private = @( Get-ChildItem -Path $PSScriptRoot\Private\*.ps1 -ErrorAction SilentlyContinue )

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
