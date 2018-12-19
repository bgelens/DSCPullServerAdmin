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

    $mdbConnection = [DSCPullServerMDBConnection]::new()
    $mdbConnection.Active = $true
    $mdbConnection.Index = 2

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

            Mock -CommandName Invoke-DSCPullServerMDBCommand

            Get-DSCPullServerAdminDevice -Connection $eseConnection

            Assert-MockCalled -CommandName Get-DSCPullServerESERecord -Exactly -Times 1 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerSQLCommand -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerMDBCommand -Exactly -Times 0 -Scope it
        }

        It 'Should Call Get-DSCPullServerESERecord when ESEFilePath is used and is valid (ESE)' {
            Mock -CommandName PreProc -MockWith {
                $eseConnection
            }

            Mock -CommandName Get-DSCPullServerESERecord

            Mock -CommandName Invoke-DSCPullServerSQLCommand

            Mock -CommandName Invoke-DSCPullServerMDBCommand

            Mock -CommandName Assert-DSCPullServerDatabaseFilePath -MockWith {
                $true
            }

            Get-DSCPullServerAdminDevice -ESEFilePath 'c:\bogus.edb'

            Assert-MockCalled -CommandName Get-DSCPullServerESERecord -Exactly -Times 1 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerSQLCommand -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerMDBCommand -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Assert-DSCPullServerDatabaseFilePath -Exactly -Times 1 -Scope it
        }

        It 'Should throw and not Call Get-DSCPullServerESERecord when ESEFilePath is used and is not valid (ESE)' {
            Mock -CommandName PreProc

            Mock -CommandName Get-DSCPullServerESERecord

            Mock -CommandName Invoke-DSCPullServerSQLCommand

            Mock -CommandName Invoke-DSCPullServerMDBCommand

            Mock -CommandName Assert-DSCPullServerDatabaseFilePath -MockWith {
                throw 'invalid edb'
            }

            { Get-DSCPullServerAdminDevice -ESEFilePath 'c:\bogus.edb' } | Should -Throw

            Assert-MockCalled -CommandName PreProc -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Get-DSCPullServerESERecord -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerSQLCommand -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerMDBCommand -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Assert-DSCPullServerDatabaseFilePath -Exactly -Times 1 -Scope it
        }

        It 'Should Call Get-DSCPullServerESERecord when active Connection is ESE' {
            $script:DSCPullServerConnections = [System.Collections.ArrayList]::new()
            [void] $script:DSCPullServerConnections.Add($eseConnection)

            Mock -CommandName PreProc -MockWith {
                $eseConnection
            }

            Mock -CommandName Get-DSCPullServerESERecord

            Mock -CommandName Invoke-DSCPullServerSQLCommand

            Mock -CommandName Invoke-DSCPullServerMDBCommand

            Get-DSCPullServerAdminDevice

            Assert-MockCalled -CommandName Get-DSCPullServerESERecord -Exactly -Times 1 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerSQLCommand -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerMDBCommand -Exactly -Times 0 -Scope it
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

            Mock -CommandName Invoke-DSCPullServerMDBCommand

            $result = Get-DSCPullServerAdminDevice -TargetName 'bogusTargetName' -ConfigurationID ([guid]::Empty)
            $result.TargetName | Should -Be 'bogusTargetName'
            $result.ConfigurationID | Should -Be ([guid]::Empty)

            Assert-MockCalled -CommandName Get-DSCPullServerESERecord -Exactly -Times 1 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerSQLCommand -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerMDBCommand -Exactly -Times 0 -Scope it
        }

        It 'Should Call Invoke-DSCPullServerSQLCommand when Connection passed is SQL' {
            Mock -CommandName PreProc -MockWith {
                $sqlConnection
            }

            Mock -CommandName Get-DSCPullServerESERecord

            Mock -CommandName Invoke-DSCPullServerSQLCommand

            Mock -CommandName Invoke-DSCPullServerMDBCommand

            Get-DSCPullServerAdminDevice -Connection $sqlConnection

            Assert-MockCalled -CommandName Get-DSCPullServerESERecord -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerSQLCommand -Exactly -Times 1 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerMDBCommand -Exactly -Times 0 -Scope it
        }

        It 'Should Call Invoke-DSCPullServerMDBCommand when Connection passed is MDB' {
            Mock -CommandName PreProc -MockWith {
                $mdbConnection
            }

            Mock -CommandName Get-DSCPullServerESERecord

            Mock -CommandName Invoke-DSCPullServerSQLCommand

            Mock -CommandName Invoke-DSCPullServerMDBCommand

            Get-DSCPullServerAdminDevice -Connection $mdbConnection

            Assert-MockCalled -CommandName Get-DSCPullServerESERecord -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerSQLCommand -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerMDBCommand -Exactly -Times 1 -Scope it
        }

        It 'Should Call Invoke-DSCPullServerMDBCommand when MDBFilePath is used and is valid (MDB)' {
            Mock -CommandName PreProc -MockWith {
                $mdbConnection
            }

            Mock -CommandName Get-DSCPullServerESERecord

            Mock -CommandName Invoke-DSCPullServerSQLCommand

            Mock -CommandName Invoke-DSCPullServerMDBCommand

            Mock -CommandName Assert-DSCPullServerDatabaseFilePath -MockWith {
                $true
            }

            Get-DSCPullServerAdminDevice -MDBFilePath 'c:\bogus.mdb'

            Assert-MockCalled -CommandName Get-DSCPullServerESERecord -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerSQLCommand -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerMDBCommand -Exactly -Times 1 -Scope it
        }

        It 'Should throw and not Call Invoke-DSCPullServerMDBCommand when MDBFilePath is used and is not valid (MDB)' {
            Mock -CommandName PreProc

            Mock -CommandName Get-DSCPullServerESERecord

            Mock -CommandName Invoke-DSCPullServerSQLCommand

            Mock -CommandName Invoke-DSCPullServerMDBCommand

            Mock -CommandName Assert-DSCPullServerDatabaseFilePath -MockWith {
                throw 'invalid mdb'
            }

            { Get-DSCPullServerAdminDevice -MDBFilePath 'c:\bogus.mdb' } | Should -Throw

            Assert-MockCalled -CommandName PreProc -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Get-DSCPullServerESERecord -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerSQLCommand -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerMDBCommand -Exactly -Times 0 -Scope it
        }

        It 'Should Call Invoke-DSCPullServerSQLCommand when active Connection is SQL' {
            $script:DSCPullServerConnections = [System.Collections.ArrayList]::new()
            [void] $script:DSCPullServerConnections.Add($sqlConnection)

            Mock -CommandName PreProc -MockWith {
                $sqlConnection
            }

            Mock -CommandName Get-DSCPullServerESERecord

            Mock -CommandName Invoke-DSCPullServerSQLCommand

            Mock -CommandName Invoke-DSCPullServerMDBCommand

            Get-DSCPullServerAdminDevice

            Assert-MockCalled -CommandName Get-DSCPullServerESERecord -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerSQLCommand -Exactly -Times 1 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerMDBCommand -Exactly -Times 0 -Scope it
        }

        It 'Should Call Invoke-DSCPullServerMDBCommand when active Connection is MDB' {
            $script:DSCPullServerConnections = [System.Collections.ArrayList]::new()
            [void] $script:DSCPullServerConnections.Add($mdbConnection)

            Mock -CommandName PreProc -MockWith {
                $mdbConnection
            }

            Mock -CommandName Get-DSCPullServerESERecord

            Mock -CommandName Invoke-DSCPullServerSQLCommand

            Mock -CommandName Invoke-DSCPullServerMDBCommand

            Get-DSCPullServerAdminDevice

            Assert-MockCalled -CommandName Get-DSCPullServerESERecord -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerSQLCommand -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerMDBCommand -Exactly -Times 1 -Scope it
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

            Mock -CommandName Invoke-DSCPullServerMDBCommand

            $result = Get-DSCPullServerAdminDevice -TargetName 'bogusTargetName' -ConfigurationID ([guid]::Empty) 4>&1
            $result | Should -Be "SELECT * FROM Devices WHERE TargetName like 'bogusTargetName' AND ConfigurationID = '00000000-0000-0000-0000-000000000000'"

            Assert-MockCalled -CommandName Get-DSCPullServerESERecord -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerSQLCommand -Exactly -Times 1 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerMDBCommand -Exactly -Times 0 -Scope it
        }

        It 'Should Call Invoke-DSCPullServerMDBCommand with filters when active Connection is MDB and filters specified' {
            $script:DSCPullServerConnections = [System.Collections.ArrayList]::new()
            [void] $script:DSCPullServerConnections.Add($mdbConnection)

            Mock -CommandName PreProc -MockWith {
                $mdbConnection
            }

            Mock -CommandName Get-DSCPullServerESERecord

            Mock -CommandName Invoke-DSCPullServerSQLCommand

            Mock -CommandName Invoke-DSCPullServerMDBCommand -MockWith {
                param (
                    $Script
                )
                Write-Verbose -Message $Script -Verbose
            }

            $result = Get-DSCPullServerAdminDevice -TargetName 'bogusTargetName' -ConfigurationID ([guid]::Empty) 4>&1
            $result | Should -Be "SELECT * FROM Devices WHERE TargetName = 'bogusTargetName' AND ConfigurationID = '00000000-0000-0000-0000-000000000000'"

            Assert-MockCalled -CommandName Get-DSCPullServerESERecord -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerSQLCommand -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerMDBCommand -Exactly -Times 1 -Scope it
        }

        It 'Should throw when active Connection is MDB and wildcards are used' {
            $script:DSCPullServerConnections = [System.Collections.ArrayList]::new()
            [void] $script:DSCPullServerConnections.Add($mdbConnection)

            Mock -CommandName PreProc -MockWith {
                $mdbConnection
            }

            Mock -CommandName Get-DSCPullServerESERecord

            Mock -CommandName Invoke-DSCPullServerSQLCommand

            Mock -CommandName Invoke-DSCPullServerMDBCommand

            { Get-DSCPullServerAdminDevice -TargetName 'bogusTargetName*' } | Should -Throw

            Assert-MockCalled -CommandName Get-DSCPullServerESERecord -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerSQLCommand -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerMDBCommand -Exactly -Times 0 -Scope it
        }

        It 'Should not throw when active Connection is SQL and wildcards are used' {
            $script:DSCPullServerConnections = [System.Collections.ArrayList]::new()
            [void] $script:DSCPullServerConnections.Add($sqlConnection)

            Mock -CommandName PreProc -MockWith {
                $sqlConnection
            }

            Mock -CommandName Get-DSCPullServerESERecord

            Mock -CommandName Invoke-DSCPullServerSQLCommand

            Mock -CommandName Invoke-DSCPullServerMDBCommand

            { Get-DSCPullServerAdminDevice -TargetName 'bogusTargetName*' } | Should -Not -Throw

            Assert-MockCalled -CommandName Get-DSCPullServerESERecord -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerSQLCommand -Exactly -Times 1 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerMDBCommand -Exactly -Times 0 -Scope it
        }

        It 'Should not throw when active Connection is ESE and wildcards are used' {
            $script:DSCPullServerConnections = [System.Collections.ArrayList]::new()
            [void] $script:DSCPullServerConnections.Add($eseConnection)

            Mock -CommandName PreProc -MockWith {
                $eseConnection
            }

            Mock -CommandName Get-DSCPullServerESERecord

            Mock -CommandName Invoke-DSCPullServerSQLCommand

            Mock -CommandName Invoke-DSCPullServerMDBCommand

            { Get-DSCPullServerAdminDevice -TargetName 'bogusTargetName*' } | Should -Not -Throw

            Assert-MockCalled -CommandName Get-DSCPullServerESERecord -Exactly -Times 1 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerSQLCommand -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerMDBCommand -Exactly -Times 0 -Scope it
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

            Mock -CommandName Invoke-DSCPullServerMDBCommand

            Mock -CommandName Write-Error

            Get-DSCPullServerAdminDevice

            Assert-MockCalled -CommandName Get-DSCPullServerESERecord -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerSQLCommand -Exactly -Times 1 -Scope it
            Assert-MockCalled -CommandName Write-Error -Exactly -Times 1 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerMDBCommand -Exactly -Times 0 -Scope it
        }

        It 'Should throw when Invoke-DSCPullServerMDBCommand result cannot be used to instantiate DSCDevice object' {
            $script:DSCPullServerConnections = [System.Collections.ArrayList]::new()
            [void] $script:DSCPullServerConnections.Add($mdbConnection)

            Mock -CommandName PreProc -MockWith {
                $mdbConnection
            }

            Mock -CommandName Get-DSCPullServerESERecord

            Mock -CommandName Invoke-DSCPullServerSQLCommand

            Mock -CommandName Invoke-DSCPullServerMDBCommand -MockWith {
                'invaliddata'
            }

            Mock -CommandName Write-Error

            Get-DSCPullServerAdminDevice

            Assert-MockCalled -CommandName Get-DSCPullServerESERecord -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerSQLCommand -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Write-Error -Exactly -Times 1 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerMDBCommand -Exactly -Times 1 -Scope it
        }
    }
}
