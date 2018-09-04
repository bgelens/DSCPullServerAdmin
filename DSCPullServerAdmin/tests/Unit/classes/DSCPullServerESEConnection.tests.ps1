$here = $PSScriptRoot

$modulePath = "$here\..\..\.."
$moduleName = Split-Path -Path $modulePath -Leaf

InModuleScope $moduleName {
    Describe DSCPullServerESEConnection {
        Context 'Type creation' {
            It 'Has created a type named DSCPullServerESEConnection' {
                'DSCPullServerESEConnection' -as [Type] | Should -BeOfType [Type]
            }
        }

        Context 'Constructors' {
            It 'Has a default constructor' {
                $instance = [DSCPullServerESEConnection]::new()
                $instance | Should -Not -BeNullOrEmpty
                $instance.GetType().Name | Should -Be 'DSCPullServerESEConnection'
            }

            It 'Should throw when invalid path is used' {
                { [DSCPullServerESEConnection]::new('bogusPath') } |
                    Should -Throw
            }
        }
    }
}
