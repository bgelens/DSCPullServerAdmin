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

    Describe Set-DSCPullServerAdminConnectionActive {
        It 'Should change the active connection when passed connection is not currently active' {
            Mock -CommandName Get-DSCPullServerAdminConnection -MockWith {
                $script:DSCPullServerConnections.Where{$_.Active}
            }

            Set-DSCPullServerAdminConnectionActive -Connection $eseConnection
            $eseConnection.Active | Should -BeTrue
            $sqlConnection.Active | Should -BeFalse
        }
    }
}
