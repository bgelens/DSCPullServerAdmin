$here = $PSScriptRoot

$modulePath = "$here\..\..\.."
$moduleName = Split-Path -Path $modulePath -Leaf

InModuleScope $moduleName {
    Describe PreProc {
        Mock -CommandName New-DSCPullServerAdminConnection -MockWith {
            param (
                [Parameter(ValueFromRemainingArguments)]
                [psobject] $PassedArgs
            )
            $PassedArgs | ForEach-Object -Process {
                if ($_ -match '^-') {
                    $_.TrimStart('-').TrimEnd(':')
                }
            }
        }

        It 'Should invoke Test-DefaultDSCPullServerConnection when ParameterSetName is Connection' {
            $sqlConnection = [DSCPullServerSQLConnection]::new()
            $sqlConnection.Active = $true
            $sqlConnection.Index = 0

            Mock -CommandName Test-DefaultDSCPullServerConnection -MockWith {
                $sqlConnection
            }

            $returnedConnection = PreProc -ParameterSetName 'Connection' -Connection $sqlConnection

            $returnedConnection | Should -Be $sqlConnection
            Assert-MockCalled -CommandName Test-DefaultDSCPullServerConnection -Times 1 -Exactly -Scope It
            Assert-MockCalled -CommandName New-DSCPullServerAdminConnection -Times 0 -Exactly -Scope It
        }

        It 'Should create a new SQL connection when ParameterSetName is SQL' {
            $result = PreProc -ParameterSetName 'SQL' -SQLServer 'bogusServer' -Credential ([pscredential]::Empty) -Database 'bogusDb'

            $result | Should -Contain 'SQLServer'
            Assert-MockCalled -CommandName New-DSCPullServerAdminConnection -Times 1 -Exactly -Scope It
        }

        It 'Should create a new ESE conneciton when ParameterSetname is ESE' {
            $result = PreProc -ParameterSetName 'ESE' -ESEFilePath 'bogusPath'

            $result | Should -Contain 'ESEFilePath'
            Assert-MockCalled -CommandName New-DSCPullServerAdminConnection -Times 1 -Exactly -Scope It
        }
    }
}
