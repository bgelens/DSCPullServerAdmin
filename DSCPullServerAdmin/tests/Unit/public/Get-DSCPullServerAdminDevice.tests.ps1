$here = $PSScriptRoot

$modulePath = "$here\..\..\.."
$moduleName = Split-Path -Path $modulePath -Leaf

InModuleScope $moduleName {
    $eseConnection = [DSCPullServerESEConnection]::new()
    $eseConnection.Index = 0
    $eseConnection.Active = $true

    $sqlConnection = [DSCPullServerSQLConnection]::new()
    $sqlConnection.Active = $true
    $sqlConnection.Index = 1

    Describe Get-DSCPullServerAdminDevice {
        BeforeEach {
            $script:DSCPullServerConnections = $null
        }

        It 'Should Call Get-DSCPullServerESERecord when Connection passed is ESE' {
            Mock -CommandName PreProc -MockWith {
                $eseConnection
            }

            Mock -CommandName Get-DSCPullServerESERecord
            Mock -CommandName Invoke-DSCPullServerSQLCommand

            Get-DSCPullServerAdminDevice -Connection $eseConnection

            Assert-MockCalled -CommandName Get-DSCPullServerESERecord -Exactly -Times 1 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerSQLCommand -Exactly -Times 0 -Scope it
        }

        It 'Should Call Get-DSCPullServerESERecord when active Connection is ESE' {
            $script:DSCPullServerConnections = [System.Collections.ArrayList]::new()
            [void] $script:DSCPullServerConnections.Add($eseConnection)

            Mock -CommandName PreProc -MockWith {
                $eseConnection
            }

            Mock -CommandName Get-DSCPullServerESERecord
            Mock -CommandName Invoke-DSCPullServerSQLCommand

            Get-DSCPullServerAdminDevice

            Assert-MockCalled -CommandName Get-DSCPullServerESERecord -Exactly -Times 1 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerSQLCommand -Exactly -Times 0 -Scope it
        }

        It 'Should Call Get-DSCPullServerESERecord with filters when active Connection is ESE and filters specified' {
            $script:DSCPullServerConnections = [System.Collections.ArrayList]::new()
            [void] $script:DSCPullServerConnections.Add($eseConnection)

            Mock -CommandName PreProc -MockWith {
                $eseConnection
            }

            Mock -CommandName Get-DSCPullServerESERecord -MockWith {
                param (
                    $TargetName,
                    $ConfigurationID
                )

                [pscustomobject]@{
                    TargetName = $TargetName
                    ConfigurationID = $ConfigurationID
                }
            }

            Mock -CommandName Invoke-DSCPullServerSQLCommand

            $result = Get-DSCPullServerAdminDevice -TargetName 'bogusTargetName' -ConfigurationID ([guid]::Empty)
            $result.TargetName | Should -Be 'bogusTargetName'
            $result.ConfigurationID | Should -Be ([guid]::Empty)

            Assert-MockCalled -CommandName Get-DSCPullServerESERecord -Exactly -Times 1 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerSQLCommand -Exactly -Times 0 -Scope it
        }

        It 'Should Call Invoke-DSCPullServerSQLCommand when Connection passed is SQL' {
            Mock -CommandName PreProc -MockWith {
                $sqlConnection
            }

            Mock -CommandName Get-DSCPullServerESERecord
            Mock -CommandName Invoke-DSCPullServerSQLCommand

            Get-DSCPullServerAdminDevice -Connection $sqlConnection

            Assert-MockCalled -CommandName Get-DSCPullServerESERecord -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerSQLCommand -Exactly -Times 1 -Scope it
        }

        It 'Should Call Invoke-DSCPullServerSQLCommand when active Connection is SQL' {
            $script:DSCPullServerConnections = [System.Collections.ArrayList]::new()
            [void] $script:DSCPullServerConnections.Add($sqlConnection)

            Mock -CommandName PreProc -MockWith {
                $sqlConnection
            }

            Mock -CommandName Get-DSCPullServerESERecord
            Mock -CommandName Invoke-DSCPullServerSQLCommand

            Get-DSCPullServerAdminDevice

            Assert-MockCalled -CommandName Get-DSCPullServerESERecord -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerSQLCommand -Exactly -Times 1 -Scope it
        }

        It 'Should Call Invoke-DSCPullServerSQLCommand with filters when active Connection is SQL and filters specified' {
            $script:DSCPullServerConnections = [System.Collections.ArrayList]::new()
            [void] $script:DSCPullServerConnections.Add($sqlConnection)

            Mock -CommandName PreProc -MockWith {
                $sqlConnection
            }

            Mock -CommandName Get-DSCPullServerESERecord
            Mock -CommandName Invoke-DSCPullServerSQLCommand -MockWith {
                param (
                    $Script
                )
                Write-Verbose -Message $Script -Verbose
            }

            $result = Get-DSCPullServerAdminDevice -TargetName 'bogusTargetName' -ConfigurationID ([guid]::Empty) 4>&1
            $result | Should -Be "SELECT * FROM Devices WHERE TargetName like 'bogusTargetName' AND ConfigurationID = '00000000-0000-0000-0000-000000000000'"

            Assert-MockCalled -CommandName Get-DSCPullServerESERecord -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerSQLCommand -Exactly -Times 1 -Scope it
        }

        It 'Should throw when Invoke-DSCPullServerSQLCommand result cannot be used to instantiate DSCDevice object' {
            $script:DSCPullServerConnections = [System.Collections.ArrayList]::new()
            [void] $script:DSCPullServerConnections.Add($sqlConnection)

            Mock -CommandName PreProc -MockWith {
                $sqlConnection
            }

            Mock -CommandName Get-DSCPullServerESERecord
            Mock -CommandName Invoke-DSCPullServerSQLCommand -MockWith {
                'invaliddata'
            }

            Mock -CommandName Write-Error

            Get-DSCPullServerAdminDevice

            Assert-MockCalled -CommandName Get-DSCPullServerESERecord -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerSQLCommand -Exactly -Times 1 -Scope it
            Assert-MockCalled -CommandName Write-Error -Exactly -Times 1 -Scope it
        }
    }
}
