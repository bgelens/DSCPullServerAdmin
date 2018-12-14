$here = $PSScriptRoot

$modulePath = "$here\..\..\.."
$moduleName = Split-Path -Path $modulePath -Leaf

InModuleScope $moduleName {
    $sqlConnection = [DSCPullServerSQLConnection]::new()
    $sqlConnection.Active = $true
    $sqlConnection.Index = 0

    $eseConnection = [DSCPullServerESEConnection]::new()
    $eseConnection.Index = 1
    $eseConnection.Active = $false

    $mdbConnection = [DSCPullServerMDBConnection]::new()
    $mdbConnection.Index = 2
    $mdbConnection.Active = $false

    $registration = [DSCNodeRegistration]::new()
    $registration.AgentId = [guid]::Empty

    function GetRegistrationFromEDB {
        $script:GetConnection = $eseConnection
        $registration
    }

    Describe Set-DSCPullServerAdminRegistration {
        It 'Should update a registration when it is passed in via InputObject (pipeline) SQL' {
            Mock -CommandName Get-DSCPullServerAdminRegistration

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

            $result = $registration | Set-DSCPullServerAdminRegistration -ConfigurationNames 'bogusConfig' -Confirm:$false 4>&1
            $result | Should -Not -BeNullOrEmpty

            Assert-MockCalled -CommandName Get-DSCPullServerAdminRegistration -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerSQLCommand -Exactly -Times 1 -Scope it
            Assert-MockCalled -CommandName Set-DSCPullServerESERecord -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerMDBCommand -Exactly -Times 0 -Scope it
        }

        It 'Should update a registration when it is passed in via InputObject (pipeline) MDB' {
            Mock -CommandName Get-DSCPullServerAdminRegistration

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

            $result = $registration | Set-DSCPullServerAdminRegistration -ConfigurationNames 'bogusConfig' -Confirm:$false 4>&1
            $result | Should -Not -BeNullOrEmpty

            Assert-MockCalled -CommandName Get-DSCPullServerAdminRegistration -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerSQLCommand -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Set-DSCPullServerESERecord -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerMDBCommand -Exactly -Times 1 -Scope it
        }

        It 'Should update a registration when it is passed in via InputObject (pipeline) ESE' {
            Mock -CommandName Get-DSCPullServerAdminRegistration

            Mock -CommandName Invoke-DSCPullServerSQLCommand

            Mock -CommandName Invoke-DSCPullServerMDBCommand

            Mock -CommandName PreProc -MockWith {
                $eseConnection
            }

            GetRegistrationFromEDB | Set-DSCPullServerAdminRegistration -ConfigurationNames 'bogusConfig' -Confirm:$false 4>&1

            Assert-MockCalled -CommandName Get-DSCPullServerAdminRegistration -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerSQLCommand -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Set-DSCPullServerESERecord -Exactly -Times 1 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerMDBCommand -Exactly -Times 0 -Scope it
        }

        It 'Should update a registration when AgentId was specified and registration was found (SQL)' {
            Mock -CommandName Get-DSCPullServerAdminRegistration -MockWith {
                $registration
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

            $result = Set-DSCPullServerAdminRegistration -AgentId ([guid]::Empty) -ConfigurationNames 'bogusConfig' -Connection $sqlConnection -Confirm:$false 4>&1
            $result | Should -Not -BeNullOrEmpty

            Assert-MockCalled -CommandName Get-DSCPullServerAdminRegistration -Exactly -Times 1 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerSQLCommand -Exactly -Times 1 -Scope it
            Assert-MockCalled -CommandName Set-DSCPullServerESERecord -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerMDBCommand -Exactly -Times 0 -Scope it
        }

        It 'Should update a registration when AgentId was specified and registration was found (MDB)' {
            Mock -CommandName Get-DSCPullServerAdminRegistration -MockWith {
                $registration
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

            $result = Set-DSCPullServerAdminRegistration -AgentId ([guid]::Empty) -ConfigurationNames 'bogusConfig' -Connection $mdbConnection -Confirm:$false 4>&1
            $result | Should -Not -BeNullOrEmpty

            Assert-MockCalled -CommandName Get-DSCPullServerAdminRegistration -Exactly -Times 1 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerSQLCommand -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Set-DSCPullServerESERecord -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerMDBCommand -Exactly -Times 1 -Scope it
        }

        It 'Should update a registration when AgentId was specified and registration was found and MDBFilePath was used (MDB)' {
            Mock -CommandName Get-DSCPullServerAdminRegistration -MockWith {
                $registration
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

            { Set-DSCPullServerAdminRegistration -AgentId ([guid]::Empty) -ConfigurationNames 'bogusConfig' -MDBFilePath 'c:\bogus.mdb' -Confirm:$false 4>&1 } |
                Should -Not -Throw

            Assert-MockCalled -CommandName Get-DSCPullServerAdminRegistration -Exactly -Times 1 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerSQLCommand -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Set-DSCPullServerESERecord -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerMDBCommand -Exactly -Times 1 -Scope it
        }

        It 'Should not update a registration when MDBFilePath is invalid (MDB)' {
            Mock -CommandName Get-DSCPullServerAdminRegistration

            Mock -CommandName Invoke-DSCPullServerSQLCommand

            Mock -CommandName Invoke-DSCPullServerMDBCommand

            Mock -CommandName Set-DSCPullServerESERecord

            Mock -CommandName PreProc

            Mock -CommandName Assert-DSCPullServerDatabaseFilePath -MockWith {
                throw 'invalid mdb'
            }

            { Set-DSCPullServerAdminRegistration -AgentId ([guid]::Empty) -ConfigurationNames 'bogusConfig' -MDBFilePath 'c:\bogus.mdb' -Confirm:$false 4>&1 } |
                Should -Throw

            Assert-MockCalled -CommandName PreProc -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Get-DSCPullServerAdminRegistration -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerSQLCommand -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Set-DSCPullServerESERecord -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerMDBCommand -Exactly -Times 0 -Scope it
        }

        It 'Should update a registration when AgentId was specified and registration was found (ESE)' {
            Mock -CommandName Get-DSCPullServerAdminRegistration -MockWith {
                $registration
            }

            Mock -CommandName Invoke-DSCPullServerSQLCommand

            Mock -CommandName Invoke-DSCPullServerMDBCommand

            Mock -CommandName Set-DSCPullServerESERecord

            Mock -CommandName PreProc -MockWith {
                $eseConnection
            }

            Set-DSCPullServerAdminRegistration -AgentId ([guid]::Empty) -ConfigurationNames 'bogusConfig' -Connection $eseConnection -Confirm:$false 4>&1

            Assert-MockCalled -CommandName Get-DSCPullServerAdminRegistration -Exactly -Times 2 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerSQLCommand -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Set-DSCPullServerESERecord -Exactly -Times 1 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerMDBCommand -Exactly -Times 0 -Scope it
        }

        It 'Should update a registration when AgentId was specified and registration was found and ESEFilePath is used (ESE)' {
            Mock -CommandName Get-DSCPullServerAdminRegistration -MockWith {
                $registration
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

            { Set-DSCPullServerAdminRegistration -AgentId ([guid]::Empty) -ConfigurationNames 'bogusConfig' -ESEFilePath 'c:\bogus.edb' -Confirm:$false 4>&1 } |
                Should -Not -Throw

            Assert-MockCalled -CommandName Get-DSCPullServerAdminRegistration -Exactly -Times 2 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerSQLCommand -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Set-DSCPullServerESERecord -Exactly -Times 1 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerMDBCommand -Exactly -Times 0 -Scope it
        }

        It 'Should not update a registration when ESEFilePath is invalid (ESE)' {
            Mock -CommandName Get-DSCPullServerAdminRegistration

            Mock -CommandName Invoke-DSCPullServerSQLCommand

            Mock -CommandName Invoke-DSCPullServerMDBCommand

            Mock -CommandName Set-DSCPullServerESERecord

            Mock -CommandName PreProc

            Mock -CommandName Assert-DSCPullServerDatabaseFilePath -MockWith {
                throw 'invalid edb'
            }

            { Set-DSCPullServerAdminRegistration -AgentId ([guid]::Empty) -ConfigurationNames 'bogusConfig' -ESEFilePath 'c:\bogus.edb' -Confirm:$false 4>&1 } |
                Should -Throw

            Assert-MockCalled -CommandName PreProc -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Get-DSCPullServerAdminRegistration -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerSQLCommand -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Set-DSCPullServerESERecord -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerMDBCommand -Exactly -Times 0 -Scope it
        }

        It 'Should throw when AgentId was specified but registration was not found (SQL)' {
            Mock -CommandName Get-DSCPullServerAdminRegistration

            Mock -CommandName Invoke-DSCPullServerSQLCommand

            Mock -CommandName Invoke-DSCPullServerMDBCommand

            Mock -CommandName Set-DSCPullServerESERecord

            Mock -CommandName PreProc -MockWith {
                $sqlConnection
            }

            { Set-DSCPullServerAdminRegistration -AgentId ([guid]::Empty) -ConfigurationNames 'bogusConfig' -Confirm:$false } |
                Should -Throw

            Assert-MockCalled -CommandName Get-DSCPullServerAdminRegistration -Exactly -Times 1 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerSQLCommand -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Set-DSCPullServerESERecord -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerMDBCommand -Exactly -Times 0 -Scope it
        }

        It 'Should throw when AgentId was specified but registration was not found (MDB)' {
            Mock -CommandName Get-DSCPullServerAdminRegistration

            Mock -CommandName Invoke-DSCPullServerSQLCommand

            Mock -CommandName Invoke-DSCPullServerMDBCommand

            Mock -CommandName Set-DSCPullServerESERecord

            Mock -CommandName PreProc -MockWith {
                $mdbConnection
            }

            { Set-DSCPullServerAdminRegistration -AgentId ([guid]::Empty) -ConfigurationNames 'bogusConfig' -Confirm:$false } |
                Should -Throw

            Assert-MockCalled -CommandName Get-DSCPullServerAdminRegistration -Exactly -Times 1 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerSQLCommand -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Set-DSCPullServerESERecord -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerMDBCommand -Exactly -Times 0 -Scope it
        }

        It 'Should throw when AgentId was specified but registration was not found (ESE)' {
            Mock -CommandName Get-DSCPullServerAdminRegistration

            Mock -CommandName Invoke-DSCPullServerSQLCommand

            Mock -CommandName Invoke-DSCPullServerMDBCommand

            Mock -CommandName Set-DSCPullServerESERecord

            Mock -CommandName PreProc -MockWith {
                $eseConnection
            }

            { Set-DSCPullServerAdminRegistration -AgentId ([guid]::Empty) -ConfigurationNames 'bogusConfig' -Confirm:$false } |
                Should -Throw

            Assert-MockCalled -CommandName Get-DSCPullServerAdminRegistration -Exactly -Times 1 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerSQLCommand -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Set-DSCPullServerESERecord -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerMDBCommand -Exactly -Times 0 -Scope it
        }

        It 'Should have ShouldProcess before calling Invoke-DSCPullServerSQLCommand' {
            Mock -CommandName Get-DSCPullServerAdminRegistration

            Mock -CommandName Invoke-DSCPullServerSQLCommand

            Mock -CommandName Invoke-DSCPullServerMDBCommand

            Mock -CommandName Set-DSCPullServerESERecord

            Mock -CommandName PreProc -MockWith {
                $sqlConnection
            }

            $registration | Set-DSCPullServerAdminRegistration -ConfigurationNames 'bogusConfig' -WhatIf

            Assert-MockCalled -CommandName Get-DSCPullServerAdminRegistration -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerSQLCommand -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Set-DSCPullServerESERecord -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerMDBCommand -Exactly -Times 0 -Scope it
        }

        It 'Should have ShouldProcess before calling Invoke-DSCPullServerMDBCommand' {
            Mock -CommandName Get-DSCPullServerAdminRegistration

            Mock -CommandName Invoke-DSCPullServerSQLCommand

            Mock -CommandName Invoke-DSCPullServerMDBCommand

            Mock -CommandName Set-DSCPullServerESERecord

            Mock -CommandName PreProc -MockWith {
                $mdbConnection
            }

            $registration | Set-DSCPullServerAdminRegistration -ConfigurationNames 'bogusConfig' -WhatIf

            Assert-MockCalled -CommandName Get-DSCPullServerAdminRegistration -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerSQLCommand -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Set-DSCPullServerESERecord -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerMDBCommand -Exactly -Times 0 -Scope it
        }

        It 'Should have ShouldProcess before calling Set-DSCPullServerESERecord' {
            Mock -CommandName Get-DSCPullServerAdminRegistration

            Mock -CommandName Invoke-DSCPullServerSQLCommand

            Mock -CommandName Invoke-DSCPullServerMDBCommand

            Mock -CommandName Set-DSCPullServerESERecord

            Mock -CommandName PreProc -MockWith {
                $eseConnection
            }

            $registration | Set-DSCPullServerAdminRegistration -ConfigurationNames 'bogusConfig' -WhatIf

            Assert-MockCalled -CommandName Get-DSCPullServerAdminRegistration -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerSQLCommand -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Set-DSCPullServerESERecord -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerMDBCommand -Exactly -Times 0 -Scope it
        }
    }
}
