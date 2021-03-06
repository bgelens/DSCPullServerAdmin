$here = $PSScriptRoot

$modulePath = "$here\..\..\.."
$moduleName = Split-Path -Path $modulePath -Leaf

InModuleScope $moduleName {
    $sqlConnection = [DSCPullServerSQLConnection]::new()
    $sqlConnection.Active = $true
    $sqlConnection.Index = 0

    $eseConnection = [DSCPullServerESEConnection]::new()
    $eseConnection.Index = 1

    $mdbConnection = [DSCPullServerMDBConnection]::new()
    $mdbConnection.Index = 2

    $report = [DSCNodeStatusReport]::new()
    $report.Id = [guid]::Empty
    $report.JobId = [guid]::Empty
    $report.NodeName = 'oldNodeName'

    function GetReportFromEDB {
        $script:GetConnection = $eseConnection
        $report
    }

    Describe Set-DSCPullServerAdminStatusReport {
        It 'Should update a statusreport when it is passed in via InputObject (pipeline) SQL' {
            Mock -CommandName Get-DSCPullServerAdminStatusReport

            Mock -CommandName Invoke-DSCPullServerSQLCommand -MockWith {
                param (
                    $script
                )
                Write-Verbose -Message $Script -Verbose
            }

            Mock -CommandName Invoke-DSCPullServerMDBCommand

            Mock -CommandName Set-DSCPullServerESERecord

            Mock -CommandName PreProc -MockWith {
                $sqlConnection
            }

            $result = $report | Set-DSCPullServerAdminStatusReport -NodeName 'newNodeName' -Confirm:$false 4>&1
            $result | Should -Not -BeNullOrEmpty

            Assert-MockCalled -CommandName Get-DSCPullServerAdminStatusReport -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerSQLCommand -Exactly -Times 1 -Scope it
            Assert-MockCalled -CommandName Set-DSCPullServerESERecord -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerMDBCommand -Exactly -Times 0 -Scope it
        }

        It 'Should update a statusreport when it is passed in via InputObject (pipeline) MDB' {
            Mock -CommandName Get-DSCPullServerAdminStatusReport

            Mock -CommandName Invoke-DSCPullServerSQLCommand

            Mock -CommandName Invoke-DSCPullServerMDBCommand -MockWith {
                param (
                    $script
                )
                Write-Verbose -Message $Script -Verbose
            }

            Mock -CommandName Set-DSCPullServerESERecord

            Mock -CommandName PreProc -MockWith {
                $mdbConnection
            }

            $result = $report | Set-DSCPullServerAdminStatusReport -NodeName 'newNodeName' -Confirm:$false 4>&1
            $result | Should -Not -BeNullOrEmpty

            Assert-MockCalled -CommandName Get-DSCPullServerAdminStatusReport -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerSQLCommand -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Set-DSCPullServerESERecord -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerMDBCommand -Exactly -Times 1 -Scope it
        }

        It 'Should update a statusreport when it is passed in via InputObject (pipeline) ESE' {
            Mock -CommandName Get-DSCPullServerAdminStatusReport

            Mock -CommandName Invoke-DSCPullServerSQLCommand

            Mock -CommandName Invoke-DSCPullServerMDBCommand

            Mock -CommandName Set-DSCPullServerESERecord

            Mock -CommandName PreProc -MockWith {
                $eseConnection
            }

            GetReportFromEDB | Set-DSCPullServerAdminStatusReport -NodeName 'newNodeName' -Confirm:$false 4>&1

            Assert-MockCalled -CommandName Get-DSCPullServerAdminStatusReport -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerSQLCommand -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Set-DSCPullServerESERecord -Exactly -Times 1 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerMDBCommand -Exactly -Times 0 -Scope it
        }

        It 'Should update a statusreport when JobId was specified and statusreport was found (SQL)' {
            Mock -CommandName Get-DSCPullServerAdminStatusReport -MockWith {
                $report
            }

            Mock -CommandName Invoke-DSCPullServerSQLCommand -MockWith {
                param (
                    $script
                )
                Write-Verbose -Message $Script -Verbose
            }

            Mock -CommandName Invoke-DSCPullServerMDBCommand

            Mock -CommandName Set-DSCPullServerESERecord

            Mock -CommandName PreProc -MockWith {
                $sqlConnection
            }

            $result = Set-DSCPullServerAdminStatusReport -JobId ([guid]::Empty) -NodeName 'newNodeName' -Connection $sqlConnection -Confirm:$false 4>&1
            $result | Should -Not -BeNullOrEmpty

            Assert-MockCalled -CommandName Get-DSCPullServerAdminStatusReport -Exactly -Times 1 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerSQLCommand -Exactly -Times 1 -Scope it
            Assert-MockCalled -CommandName Set-DSCPullServerESERecord -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerMDBCommand -Exactly -Times 0 -Scope it
        }

        It 'Should update a statusreport when JobId was specified and statusreport was found (MDB)' {
            Mock -CommandName Get-DSCPullServerAdminStatusReport -MockWith {
                $report
            }

            Mock -CommandName Invoke-DSCPullServerSQLCommand

            Mock -CommandName Invoke-DSCPullServerMDBCommand -MockWith {
                param (
                    $script
                )
                Write-Verbose -Message $Script -Verbose
            }

            Mock -CommandName Set-DSCPullServerESERecord

            Mock -CommandName PreProc -MockWith {
                $mdbConnection
            }

            $result = Set-DSCPullServerAdminStatusReport -JobId ([guid]::Empty) -NodeName 'newNodeName' -Connection $mdbConnection -Confirm:$false 4>&1
            $result | Should -Not -BeNullOrEmpty

            Assert-MockCalled -CommandName Get-DSCPullServerAdminStatusReport -Exactly -Times 1 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerSQLCommand -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Set-DSCPullServerESERecord -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerMDBCommand -Exactly -Times 1 -Scope it
        }

        It 'Should update a statusreport when JobId was specified and statusreport was found and MDBFilePath is used (MDB)' {
            Mock -CommandName Get-DSCPullServerAdminStatusReport -MockWith {
                $report
            }

            Mock -CommandName Invoke-DSCPullServerSQLCommand

            Mock -CommandName Invoke-DSCPullServerMDBCommand

            Mock -CommandName Set-DSCPullServerESERecord

            Mock -CommandName PreProc -MockWith {
                $mdbConnection
            }

            Mock -CommandName Assert-DSCPullServerDatabaseFilePath -MockWith {
                $true
            }

            { Set-DSCPullServerAdminStatusReport -JobId ([guid]::Empty) -NodeName 'newNodeName' -MDBFilePath 'c:\bogus.mdb' -Confirm:$false 4>&1 } |
                Should -Not -Throw

            Assert-MockCalled -CommandName Get-DSCPullServerAdminStatusReport -Exactly -Times 1 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerSQLCommand -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Set-DSCPullServerESERecord -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerMDBCommand -Exactly -Times 1 -Scope it
        }

        It 'Should not update a statusreport when MDBFilePath is invalid (MDB)' {
            Mock -CommandName Get-DSCPullServerAdminStatusReport

            Mock -CommandName Invoke-DSCPullServerSQLCommand

            Mock -CommandName Invoke-DSCPullServerMDBCommand

            Mock -CommandName Set-DSCPullServerESERecord

            Mock -CommandName PreProc -MockWith {
                $mdbConnection
            }

            Mock -CommandName Assert-DSCPullServerDatabaseFilePath -MockWith {
                throw 'invalid mdb'
            }

            { Set-DSCPullServerAdminStatusReport -JobId ([guid]::Empty) -NodeName 'newNodeName' -MDBFilePath 'c:\bogus.mdb' -Confirm:$false 4>&1 } |
                Should -Throw

            Assert-MockCalled -CommandName PreProc -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Get-DSCPullServerAdminStatusReport -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerSQLCommand -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Set-DSCPullServerESERecord -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerMDBCommand -Exactly -Times 0 -Scope it
        }

        It 'Should update a statusreport when JobId was specified and statusreport was found (ESE)' {
            Mock -CommandName Get-DSCPullServerAdminStatusReport -MockWith {
                $report
            }

            Mock -CommandName Invoke-DSCPullServerSQLCommand

            Mock -CommandName Invoke-DSCPullServerMDBCommand

            Mock -CommandName Set-DSCPullServerESERecord

            Mock -CommandName PreProc -MockWith {
                $eseConnection
            }

            Set-DSCPullServerAdminStatusReport -JobId ([guid]::Empty) -NodeName 'newNodeName' -Connection $eseConnection -Confirm:$false 4>&1

            Assert-MockCalled -CommandName Get-DSCPullServerAdminStatusReport -Exactly -Times 2 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerSQLCommand -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Set-DSCPullServerESERecord -Exactly -Times 1 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerMDBCommand -Exactly -Times 0 -Scope it
        }

        It 'Should update a statusreport when JobId was specified and statusreport was found and ESEFilePath is used (ESE)' {
            Mock -CommandName Get-DSCPullServerAdminStatusReport -MockWith {
                $report
            }

            Mock -CommandName Invoke-DSCPullServerSQLCommand

            Mock -CommandName Invoke-DSCPullServerMDBCommand

            Mock -CommandName Set-DSCPullServerESERecord

            Mock -CommandName PreProc -MockWith {
                $eseConnection
            }

            Mock -CommandName Assert-DSCPullServerDatabaseFilePath -MockWith {
                $true
            }

            { Set-DSCPullServerAdminStatusReport -JobId ([guid]::Empty) -NodeName 'newNodeName' -ESEFilePath 'c:\bogus.edb' -Confirm:$false 4>&1 } |
                Should -Not -Throw

            Assert-MockCalled -CommandName Get-DSCPullServerAdminStatusReport -Exactly -Times 2 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerSQLCommand -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Set-DSCPullServerESERecord -Exactly -Times 1 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerMDBCommand -Exactly -Times 0 -Scope it
        }

        It 'Should not update a statusreport when ESEFilePath is invalid (ESE)' {
            Mock -CommandName Get-DSCPullServerAdminStatusReport -MockWith {
                $report
            }

            Mock -CommandName Invoke-DSCPullServerSQLCommand

            Mock -CommandName Invoke-DSCPullServerMDBCommand

            Mock -CommandName Set-DSCPullServerESERecord

            Mock -CommandName PreProc -MockWith {
                $eseConnection
            }

            Mock -CommandName Assert-DSCPullServerDatabaseFilePath -MockWith {
                throw 'invalid edb'
            }

            { Set-DSCPullServerAdminStatusReport -JobId ([guid]::Empty) -NodeName 'newNodeName' -ESEFilePath 'c:\bogus.edb' -Confirm:$false 4>&1 } |
                Should -Throw

            Assert-MockCalled -CommandName PreProc -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Get-DSCPullServerAdminStatusReport -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerSQLCommand -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Set-DSCPullServerESERecord -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerMDBCommand -Exactly -Times 0 -Scope it
        }

        It 'Should throw when JobId was specified but statusreport was not found (SQL)' {
            Mock -CommandName Get-DSCPullServerAdminStatusReport

            Mock -CommandName Invoke-DSCPullServerSQLCommand

            Mock -CommandName PreProc -MockWith {
                $sqlConnection
            }

            Mock -CommandName Invoke-DSCPullServerMDBCommand

            Mock -CommandName Set-DSCPullServerESERecord

            { Set-DSCPullServerAdminStatusReport -JobId ([guid]::Empty) -NodeName 'newNodeName' -Confirm:$false } |
                Should -Throw

            Assert-MockCalled -CommandName Get-DSCPullServerAdminStatusReport -Exactly -Times 1 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerSQLCommand -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Set-DSCPullServerESERecord -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerMDBCommand -Exactly -Times 0 -Scope it
        }

        It 'Should throw when JobId was specified but statusreport was not found (MDB)' {
            Mock -CommandName Get-DSCPullServerAdminStatusReport

            Mock -CommandName Invoke-DSCPullServerSQLCommand

            Mock -CommandName PreProc -MockWith {
                $mdbConnection
            }

            Mock -CommandName Invoke-DSCPullServerMDBCommand

            Mock -CommandName Set-DSCPullServerESERecord

            { Set-DSCPullServerAdminStatusReport -JobId ([guid]::Empty) -NodeName 'newNodeName' -Confirm:$false } |
                Should -Throw

            Assert-MockCalled -CommandName Get-DSCPullServerAdminStatusReport -Exactly -Times 1 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerSQLCommand -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Set-DSCPullServerESERecord -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerMDBCommand -Exactly -Times 0 -Scope it
        }

        It 'Should throw when JobId was specified but statusreport was not found (ESE)' {
            Mock -CommandName Get-DSCPullServerAdminStatusReport

            Mock -CommandName Invoke-DSCPullServerSQLCommand

            Mock -CommandName PreProc -MockWith {
                $eseConnection
            }

            Mock -CommandName Invoke-DSCPullServerMDBCommand

            Mock -CommandName Set-DSCPullServerESERecord

            { Set-DSCPullServerAdminStatusReport -JobId ([guid]::Empty) -NodeName 'newNodeName' -Confirm:$false } |
                Should -Throw

            Assert-MockCalled -CommandName Get-DSCPullServerAdminStatusReport -Exactly -Times 1 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerSQLCommand -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Set-DSCPullServerESERecord -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerMDBCommand -Exactly -Times 0 -Scope it
        }

        It 'Should have ShouldProcess before calling Invoke-DSCPullServerSQLCommand' {
            Mock -CommandName Get-DSCPullServerAdminStatusReport

            Mock -CommandName Invoke-DSCPullServerSQLCommand

            Mock -CommandName Invoke-DSCPullServerMDBCommand

            Mock -CommandName PreProc -MockWith {
                $sqlConnection
            }

            Mock -CommandName Set-DSCPullServerESERecord

            $report | Set-DSCPullServerAdminStatusReport -NodeName 'newNodeName' -WhatIf

            Assert-MockCalled -CommandName Get-DSCPullServerAdminStatusReport -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerSQLCommand -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Set-DSCPullServerESERecord -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerMDBCommand -Exactly -Times 0 -Scope it
        }

        It 'Should have ShouldProcess before calling Invoke-DSCPullServerMDBCommand' {
            Mock -CommandName Get-DSCPullServerAdminStatusReport

            Mock -CommandName Invoke-DSCPullServerSQLCommand

            Mock -CommandName Invoke-DSCPullServerMDBCommand

            Mock -CommandName PreProc -MockWith {
                $mdbConnection
            }

            Mock -CommandName Set-DSCPullServerESERecord

            $report | Set-DSCPullServerAdminStatusReport -NodeName 'newNodeName' -WhatIf

            Assert-MockCalled -CommandName Get-DSCPullServerAdminStatusReport -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerSQLCommand -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Set-DSCPullServerESERecord -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerMDBCommand -Exactly -Times 0 -Scope it
        }

        It 'Should have ShouldProcess before calling Set-DSCPullServerESERecord' {
            Mock -CommandName Get-DSCPullServerAdminStatusReport

            Mock -CommandName Invoke-DSCPullServerSQLCommand

            Mock -CommandName Invoke-DSCPullServerMDBCommand

            Mock -CommandName PreProc -MockWith {
                $eseConnection
            }

            Mock -CommandName Set-DSCPullServerESERecord

            $report | Set-DSCPullServerAdminStatusReport -NodeName 'newNodeName' -WhatIf

            Assert-MockCalled -CommandName Get-DSCPullServerAdminStatusReport -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerSQLCommand -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Set-DSCPullServerESERecord -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerMDBCommand -Exactly -Times 0 -Scope it
        }
    }
}
