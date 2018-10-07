$here = $PSScriptRoot

$modulePath = "$here\..\..\.."
$moduleName = Split-Path -Path $modulePath -Leaf

InModuleScope $moduleName {
    $sqlConnection = [DSCPullServerSQLConnection]::new()
    $sqlConnection.Active = $true
    $sqlConnection.Index = 0

    Describe Test-DefaultDSCPullServerConnection {
        Mock -CommandName Write-Warning

        It 'Should return $true when a connection was found' {
            Test-DefaultDSCPullServerConnection -Connection $sqlConnection |
                Should -BeTrue

            Assert-MockCalled -CommandName Write-Warning -Times 0 -Scope It
        }

        It 'Should return $false when no connection was found' {
            

            Test-DefaultDSCPullServerConnection -Connection $null |
                Should -BeFalse

            Assert-MockCalled -CommandName Write-Warning -Times 1 -Scope It
        }
    }
}
