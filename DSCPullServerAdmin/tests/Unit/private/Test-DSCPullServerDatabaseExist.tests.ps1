$here = $PSScriptRoot

$modulePath = "$here\..\..\.."
$moduleName = Split-Path -Path $modulePath -Leaf

InModuleScope $moduleName {
    Describe Test-DSCPullServerDatabaseExist {
        It 'Should return $true when the Database Exists' {
            Mock -CommandName Invoke-DSCPullServerSQLCommand -MockWith {
                [pscustomobject]@{
                    Name = 'bogusResult'
                } | Add-Member -MemberType ScriptMethod -Name GetBoolean -Value {
                    $true
                } -PassThru
            }

            Test-DSCPullServerDatabaseExist -SQLServer bogusServer -Name bogusDb -Credential ([pscredential]::Empty) |
                Should -BeTrue
        }

        It 'Should return $false when the Database dos not Exist' {
            $sqlConnection = [DSCPullServerSQLConnection]::new()
            $sqlConnection.Active = $true
            $sqlConnection.Index = 1
            $sqlConnection.Credential = [pscredential]::Empty
            $sqlConnection.Database = 'DSC'

            Mock -CommandName Invoke-DSCPullServerSQLCommand -MockWith {
                [pscustomobject]@{
                    Name = 'bogusResult'
                } | Add-Member -MemberType ScriptMethod -Name GetBoolean -Value {
                    $false
                } -PassThru
            }

            Test-DSCPullServerDatabaseExist -Connection $sqlConnection |
                Should -BeFalse
        }
    }
}
