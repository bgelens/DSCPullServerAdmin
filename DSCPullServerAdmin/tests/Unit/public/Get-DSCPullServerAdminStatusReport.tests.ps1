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

    Describe Get-DSCPullServerAdminStatusReport {
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

            Get-DSCPullServerAdminStatusReport -Connection $eseConnection

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

            Get-DSCPullServerAdminStatusReport -ESEFilePath 'c:\bogus.edb'

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

            { Get-DSCPullServerAdminStatusReport -ESEFilePath 'c:\bogus.edb' } | Should -Throw

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

            Get-DSCPullServerAdminStatusReport

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
                    $AgentId,
                    $NodeName,
                    $JobId,
                    $FromStartTime,
                    $ToStartTime
                )

                [pscustomobject]@{
                    AgentId = $AgentId
                    NodeName = $NodeName
                    JobId = $JobId
                    FromStartTime = $FromStartTime
                    ToStartTime = $ToStartTime
                }
            }

            Mock -CommandName Invoke-DSCPullServerSQLCommand

            Mock -CommandName Invoke-DSCPullServerMDBCommand

            $result = Get-DSCPullServerAdminStatusReport `
                -AgentId ([guid]::Empty) `
                -NodeName 'bogusNode' `
                -JobId ([guid]::Empty) `
                -FromStartTime ([datetime]::MinValue) `
                -ToStartTime ([datetime]::MaxValue) 

            $result.AgentId | Should -Be ([guid]::Empty)
            $result.NodeName | Should -Be 'bogusNode'
            $result.JobId | Should -Be ([guid]::Empty)
            $result.FromStartTime | Should -Be ([datetime]::MinValue)
            $result.ToStartTime | Should -Be ([datetime]::MaxValue)

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

            Get-DSCPullServerAdminStatusReport -Connection $sqlConnection

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

            Get-DSCPullServerAdminStatusReport -Connection $mdbConnection

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

            Get-DSCPullServerAdminStatusReport -MDBFilePath 'c:\bogus.mdb'

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

            { Get-DSCPullServerAdminStatusReport -MDBFilePath 'c:\bogus.mdb' } | Should -Throw

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

            Get-DSCPullServerAdminStatusReport

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

            Get-DSCPullServerAdminStatusReport

            Assert-MockCalled -CommandName Get-DSCPullServerESERecord -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerSQLCommand -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerMDBCommand -Exactly -Times 1 -Scope it
        }

        It 'Should Call Invoke-DSCPullServerSQLCommand with filters when active Connection is SQL and filters specified without All switch' {
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

            $result = Get-DSCPullServerAdminStatusReport `
                -AgentId ([guid]::Empty) `
                -NodeName 'bogusNode' `
                -JobId ([guid]::Empty) `
                -FromStartTime ([datetime]::MinValue) `
                -ToStartTime ([datetime]::MaxValue) `
                -OperationType 'Consistency' 4>&1

            $result | Should -Be "SELECT TOP(5) * FROM StatusReport WHERE Id = '00000000-0000-0000-0000-000000000000' AND NodeName like 'bogusNode' AND StartTime >= '0001-01-01T00:00:00' AND StartTime <= '9999-12-31T23:59:59' AND JobId = '00000000-0000-0000-0000-000000000000' AND OperationType = 'Consistency'"

            Assert-MockCalled -CommandName Get-DSCPullServerESERecord -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerSQLCommand -Exactly -Times 1 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerMDBCommand -Exactly -Times 0 -Scope it
        }

        It 'Should Call Invoke-DSCPullServerMDBCommand with filters when active Connection is MDB and filters specified without All switch' {
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

            $result = Get-DSCPullServerAdminStatusReport `
                -AgentId ([guid]::Empty) `
                -NodeName 'bogusNode' `
                -JobId ([guid]::Empty) `
                -FromStartTime ([datetime]::MinValue) `
                -ToStartTime ([datetime]::MaxValue) `
                -OperationType 'Consistency' 4>&1

            $result | Should -Be "SELECT TOP 5 * FROM StatusReport WHERE Id = '00000000-0000-0000-0000-000000000000' AND NodeName = 'bogusNode' AND StartTime >= '0001-01-01T00:00:00' AND StartTime <= '9999-12-31T23:59:59' AND JobId = '00000000-0000-0000-0000-000000000000' AND OperationType = 'Consistency'"

            Assert-MockCalled -CommandName Get-DSCPullServerESERecord -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerSQLCommand -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerMDBCommand -Exactly -Times 1 -Scope it
        }

        It 'Should Call Invoke-DSCPullServerSQLCommand with filters when active Connection is SQL and filters specified with All switch' {
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

            $result = Get-DSCPullServerAdminStatusReport `
                -AgentId ([guid]::Empty) `
                -NodeName 'bogusNode' `
                -JobId ([guid]::Empty) `
                -FromStartTime ([datetime]::MinValue) `
                -ToStartTime ([datetime]::MaxValue) `
                -All 4>&1

            $result | Should -Be "SELECT * FROM StatusReport WHERE Id = '00000000-0000-0000-0000-000000000000' AND NodeName like 'bogusNode' AND StartTime >= '0001-01-01T00:00:00' AND StartTime <= '9999-12-31T23:59:59' AND JobId = '00000000-0000-0000-0000-000000000000'"

            Assert-MockCalled -CommandName Get-DSCPullServerESERecord -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerSQLCommand -Exactly -Times 1 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerMDBCommand -Exactly -Times 0 -Scope it
        }

        It 'Should Call Invoke-DSCPullServerMDBCommand with filters when active Connection is MDB and filters specified with All switch' {
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

            $result = Get-DSCPullServerAdminStatusReport `
                -AgentId ([guid]::Empty) `
                -NodeName 'bogusNode' `
                -JobId ([guid]::Empty) `
                -FromStartTime ([datetime]::MinValue) `
                -ToStartTime ([datetime]::MaxValue) `
                -All 4>&1

            $result | Should -Be "SELECT * FROM StatusReport WHERE Id = '00000000-0000-0000-0000-000000000000' AND NodeName = 'bogusNode' AND StartTime >= '0001-01-01T00:00:00' AND StartTime <= '9999-12-31T23:59:59' AND JobId = '00000000-0000-0000-0000-000000000000'"

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

            { Get-DSCPullServerAdminStatusReport -NodeName 'bogusNode*' } | Should -Throw

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

            { Get-DSCPullServerAdminStatusReport -NodeName 'bogusNode*' } | Should -Not -Throw

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

            { Get-DSCPullServerAdminStatusReport -NodeName 'bogusNode*' } | Should -Not -Throw

            Assert-MockCalled -CommandName Get-DSCPullServerESERecord -Exactly -Times 1 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerSQLCommand -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerMDBCommand -Exactly -Times 0 -Scope it
        }

        It 'Should throw when Invoke-DSCPullServerSQLCommand result cannot be used to instantiate DSCNodeStatusReport object' {
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

            Get-DSCPullServerAdminStatusReport

            Assert-MockCalled -CommandName Get-DSCPullServerESERecord -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerSQLCommand -Exactly -Times 1 -Scope it
            Assert-MockCalled -CommandName Write-Error -Exactly -Times 1 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerMDBCommand -Exactly -Times 0 -Scope it
        }

        It 'Should throw when Invoke-DSCPullServerMDBCommand result cannot be used to instantiate DSCNodeStatusReport object' {
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

            Get-DSCPullServerAdminStatusReport

            Assert-MockCalled -CommandName Get-DSCPullServerESERecord -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerSQLCommand -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Write-Error -Exactly -Times 1 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerMDBCommand -Exactly -Times 1 -Scope it
        }
    }
}
