Set-StrictMode -Version Latest

InModuleScope -ModuleName PSNow {
    Describe 'New-PSNowModule input validation' {
        It 'throws when NewModuleName is whitespace' {
            {
                New-PSNowModule -NewModuleName '   ' -BaseManifest 'Basic' -ModuleRoot 'c:\modules'
            } | Should -Throw
        }
    }
}