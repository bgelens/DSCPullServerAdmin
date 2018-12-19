$here = $PSScriptRoot

$modulePath = "$here\..\..\.."
$moduleName = Split-Path -Path $modulePath -Leaf

InModuleScope $moduleName {
    Describe DSCPullServerMDBConnection {
        Context 'Type creation' {
            It 'Has created a type named DSCPullServerMDBConnection' {
                'DSCPullServerMDBConnection' -as [Type] | Should -BeOfType [Type]
            }
        }

        Context 'Constructors' {
            It 'Has a default constructor' {
                $instance = [DSCPullServerMDBConnection]::new()
                $instance | Should -Not -BeNullOrEmpty
                $instance.GetType().Name | Should -Be 'DSCPullServerMDBConnection'
            }

            It 'Should throw when invalid path is used' {
                { [DSCPullServerMDBConnection]::new('bogusPath') } |
                    Should -Throw
            }
        }

        Context 'ConnectionString' {
            It 'Should produce expected connectionstring' {
                $tempFile = New-Item -Path TestDrive: -Name pull.mdb -ItemType File -Force
                $instance = [DSCPullServerMDBConnection]::new($tempFile.FullName)
                $instance.ConnectionString() |
                    Should -BeExactly "Provider=Microsoft.ACE.OLEDB.16.0;Data Source=$($tempFile.FullName);Persist Security Info=False"
            }
        }
    }
}
