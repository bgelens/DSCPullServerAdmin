$here = $PSScriptRoot

$modulePath = "$here\..\..\.."
$moduleName = Split-Path -Path $modulePath -Leaf

InModuleScope $moduleName {
    Describe DSCPullServerSQLConnection {
        Context 'Type creation' {
            It 'Has created a type named DSCPullServerSQLConnection' {
                'DSCPullServerSQLConnection' -as [Type] | Should -BeOfType [Type]
            }
        }

        Context 'Constructors' {
            It 'Has a default constructor' {
                $instance = [DSCPullServerSQLConnection]::new()
                $instance | Should -Not -BeNullOrEmpty
                $instance.GetType().Name | Should -Be 'DSCPullServerSQLConnection'
            }
        }
    }
}
