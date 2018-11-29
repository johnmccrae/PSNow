$manifestProperties = @{
    Path            = "C:\modules\$MyNewModuleName\PlasterManifest.xml"
    Title           = $MyNewModuleName
    TemplateName    = 'ScriptModuleTemplate'
    TemplateVersion = '0.1.0'
    TemplateType    = 'Project'
    Author          = 'John McCrae'
    Description     = 'Scaffolds the files required for a PowerShell script module'
    Tags            = 'PowerShell, Module, ModuleManifest'
}


$Folder = Split-Path -Path $manifestProperties.Path -Parent
if (-not(Test-Path -Path $Folder -PathType Container)) {
    New-Item -Path $Folder -ItemType Directory | Out-Null
}

New-PlasterManifest @manifestProperties

$Folder = Split-Path -Path $MyNewModuleName.Path -Parent
if (-not(Test-Path -Path $Folder -PathType Container)) {
    New-Item -Path $Folder -ItemType Directory | Out-Null
}