$here = $PSScriptRoot

$modulePath = "$here\..\..\.."
$moduleName = Split-Path -Path $modulePath -Leaf

InModuleScope $moduleName {
    $eseConnection = [DSCPullServerESEConnection]::new()
    $eseConnection.Index = 1

    $sqlConnection = [DSCPullServerSQLConnection]::new()
    $sqlConnection.Active = $true
    $sqlConnection.Index = 2

    $script:DSCPullServerConnections = [System.Collections.ArrayList]::new()
    [void] $script:DSCPullServerConnections.Add($eseConnection)
    [void] $script:DSCPullServerConnections.Add($sqlConnection)

    Describe Remove-DSCPullServerAdminConnection {
        It 'Should remove the provided connection from the connections saved in memory' {
            Remove-DSCPullServerAdminConnection -Connection $eseConnection
            $script:DSCPullServerConnections | Should -Not -Contain $eseConnection
        }

        It 'Should write a warning when removing the current active connection' {
            Mock -CommandName Write-Warning

            Remove-DSCPullServerAdminConnection -Connection $sqlConnection
            $script:DSCPullServerConnections | Should -Not -Contain $sqlConnection

            Assert-MockCalled -CommandName Write-Warning -Times 1 -Scope It
        }
    }
}
