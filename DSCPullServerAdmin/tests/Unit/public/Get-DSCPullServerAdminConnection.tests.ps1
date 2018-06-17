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

    Describe Get-DSCPullServerAdminConnection {
        It 'Should return all connection types when no specific type is specified' {
            $result = Get-DSCPullServerAdminConnection
            ($result | Measure-Object).Count | Should -Be -ExpectedValue 2
            $result.Type | Should -Contain 'ESE', 'SQL'
        }

        It 'Should return only SQL connection type when specified' {
            $result = Get-DSCPullServerAdminConnection -Type SQL
            ($result | Measure-Object).Count | Should -Be -ExpectedValue 1
            $result.Type | Should -Be 'SQL'
        }

        It 'Should return only ESE connection type when specified' {
            $result = Get-DSCPullServerAdminConnection -Type ESE
            ($result | Measure-Object).Count | Should -Be -ExpectedValue 1
            $result.Type | Should -Be 'ESE'
        }

        It 'Should return only correct index connection when specified' {
            $result = Get-DSCPullServerAdminConnection -Index 2
            ($result | Measure-Object).Count | Should -Be -ExpectedValue 1
            $result.Type | Should -Be 'SQL'
        }

        It 'Should return only active connection when specified' {
            $result = Get-DSCPullServerAdminConnection -OnlyShowActive
            ($result | Measure-Object).Count | Should -Be -ExpectedValue 1
            $result.Type | Should -Be 'SQL'
        }

        It 'Should return nothing when active connection specified and type is ESE which is not active' {
            $result = Get-DSCPullServerAdminConnection -OnlyShowActive -Type ESE
            ($result | Measure-Object).Count | Should -Be -ExpectedValue 0
        }
    }
}
