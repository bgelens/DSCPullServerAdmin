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

        Context 'ConnectionString' {
            $testCases = @(
                @{
                    object = [DSCPullServerSQLConnection]::new(
                        'bogusServer\instance',
                        [pscredential]::new(
                            'sa',
                            (ConvertTo-SecureString 'bogusPass' -AsPlainText -Force)
                        ),
                        'bogusDb'
                    )
                    result = 'Server=bogusServer\instance;uid=sa;pwd=bogusPass;Trusted_Connection=False;Database=bogusDb;'
                    caseDescription = 'server, credential, database'
                },
                @{
                    object = [DSCPullServerSQLConnection]::new(
                        'bogusServer\instance',
                        [pscredential]::new(
                            'sa',
                            (ConvertTo-SecureString 'bogusPass' -AsPlainText -Force)
                        )
                    )
                    result = 'Server=bogusServer\instance;uid=sa;pwd=bogusPass;Trusted_Connection=False;Database=DSC;'
                    caseDescription = 'server, credential'
                },
                @{
                    object = [DSCPullServerSQLConnection]::new(
                        'bogusServer\instance',
                        'bogusDb'
                    )
                    result = 'Server=bogusServer\instance;Integrated Security=True;Database=bogusDb;'
                    caseDescription = 'server, database'
                },
                @{
                    object = [DSCPullServerSQLConnection]::new(
                        'bogusServer\instance'
                    )
                    result = 'Server=bogusServer\instance;Integrated Security=True;'
                    caseDescription = 'server'
                },
                @{
                    object = {
                        $instanceNoDb = [DSCPullServerSQLConnection]::new()
                        $instanceNoDb.SQLServer = 'bogusServer\instance'
                        $instanceNoDb.Credential = [pscredential]::new(
                            'sa',
                            (ConvertTo-SecureString 'bogusPass' -AsPlainText -Force)
                        )
                        $instanceNoDb
                    }.Invoke()
                    result = 'Server=bogusServer\instance;uid=sa;pwd=bogusPass;Trusted_Connection=False;'
                    caseDescription = 'server'
                }
            )

            It 'Should produce expected connectionstring based on constructor signature <caseDescription>' -TestCases $testCases {
                param (
                    $object,
                    $result
                )
                $object.ConnectionString() | Should -Be $result
            }
        }
    }
}
