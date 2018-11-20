$here = $PSScriptRoot

$modulePath = "$here\..\..\.."
$moduleName = Split-Path -Path $modulePath -Leaf

InModuleScope $moduleName {
    Describe PreProc {
        $eseConnection = [DSCPullServerESEConnection]::new()
        $eseConnection.Index = 0

        It 'Should result in True when edb database contains expected tables' {
            Mock -CommandName Get-DSCPullServerESETable -MockWith {
                @(
                    'Devices',
                    'RegistrationData',
                    'StatusReport' 
                )
            }

            Test-DSCPullServerESEDatabase -Connection $eseConnection |
                Should -BeTrue
        }

        It 'Should result in False when edb database does not contains expected tables' {
            Mock -CommandName Get-DSCPullServerESETable -MockWith {
                @(
                    'bogusTable'
                )
            }

            Test-DSCPullServerESEDatabase -Connection $eseConnection |
                Should -BeFalse
        }
    }
}
