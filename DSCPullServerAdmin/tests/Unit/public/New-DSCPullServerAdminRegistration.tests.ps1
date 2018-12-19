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

    $registration = [DSCNodeRegistration]::new()
    $registration.AgentId = [guid]::Empty

    Describe New-DSCPullServerAdminRegistration {
        It 'Should create a registration when AgentId specified did not result in registration already found (SQL)' {
            Mock -CommandName Get-DSCPullServerAdminRegistration

            Mock -CommandName Invoke-DSCPullServerSQLCommand -MockWith {
                param (
                    $script
                )
                Write-Verbose -Message $Script -Verbose
            }

            Mock -CommandName Invoke-DSCPullServerMDBCommand

            Mock -CommandName PreProc -MockWith {
                $sqlConnection
            }

            Mock -CommandName Mount-DSCPullServerESEDatabase
            Mock -CommandName Open-DSCPullServerTable
            Mock -CommandName Set-DSCPullServerESERecord
            Mock -CommandName Dismount-DSCPullServerESEDatabase

            New-DSCPullServerAdminRegistration -AgentId ([guid]::Empty) -ConfigurationNames 'bogusConfig' -NodeName 'bogusNode' 4>&1

            Assert-MockCalled -CommandName Get-DSCPullServerAdminRegistration -Exactly -Times 1 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerSQLCommand -Exactly -Times 1 -Scope it
            Assert-MockCalled -CommandName Mount-DSCPullServerESEDatabase -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Open-DSCPullServerTable -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Set-DSCPullServerESERecord -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Dismount-DSCPullServerESEDatabase -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerMDBCommand -Exactly -Times 0 -Scope it
        }

        It 'Should create a registration when AgentId specified did not result in registration already found (MDB)' {
            Mock -CommandName Get-DSCPullServerAdminRegistration

            Mock -CommandName Invoke-DSCPullServerSQLCommand

            Mock -CommandName Invoke-DSCPullServerMDBCommand -MockWith {
                param (
                    $script
                )
                Write-Verbose -Message $Script -Verbose
            }

            Mock -CommandName PreProc -MockWith {
                $mdbConnection
            }

            Mock -CommandName Mount-DSCPullServerESEDatabase
            Mock -CommandName Open-DSCPullServerTable
            Mock -CommandName Set-DSCPullServerESERecord
            Mock -CommandName Dismount-DSCPullServerESEDatabase

            New-DSCPullServerAdminRegistration -AgentId ([guid]::Empty) -ConfigurationNames 'bogusConfig' -NodeName 'bogusNode' 4>&1

            Assert-MockCalled -CommandName Get-DSCPullServerAdminRegistration -Exactly -Times 1 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerSQLCommand -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Mount-DSCPullServerESEDatabase -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Open-DSCPullServerTable -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Set-DSCPullServerESERecord -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Dismount-DSCPullServerESEDatabase -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerMDBCommand -Exactly -Times 1 -Scope it
        }

        It 'Should create a registration when AgentId specified did not result in registration already found and MDBFilePath is used (MDB)' {
            Mock -CommandName Get-DSCPullServerAdminRegistration

            Mock -CommandName Invoke-DSCPullServerSQLCommand

            Mock -CommandName Invoke-DSCPullServerMDBCommand -MockWith {
                param (
                    $script
                )
                Write-Verbose -Message $Script -Verbose
            }

            Mock -CommandName Assert-DSCPullServerDatabaseFilePath -MockWith {
                $true
            }

            Mock -CommandName PreProc -MockWith {
                $mdbConnection
            }

            Mock -CommandName Mount-DSCPullServerESEDatabase
            Mock -CommandName Open-DSCPullServerTable
            Mock -CommandName Set-DSCPullServerESERecord
            Mock -CommandName Dismount-DSCPullServerESEDatabase

            { New-DSCPullServerAdminRegistration -AgentId ([guid]::Empty) -ConfigurationNames 'bogusConfig' -NodeName 'bogusNode' -MDBFilePath 'c:\bogus.mdb' 4>&1 } |
                Should -Not -Throw

            Assert-MockCalled -CommandName Get-DSCPullServerAdminRegistration -Exactly -Times 1 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerSQLCommand -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Mount-DSCPullServerESEDatabase -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Open-DSCPullServerTable -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Set-DSCPullServerESERecord -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Dismount-DSCPullServerESEDatabase -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerMDBCommand -Exactly -Times 1 -Scope it
        }

        It 'Should throw and not create a registration when MDBFilePath is invalid (MDB)' {
            Mock -CommandName Get-DSCPullServerAdminRegistration

            Mock -CommandName Invoke-DSCPullServerSQLCommand

            Mock -CommandName Invoke-DSCPullServerMDBCommand

            Mock -CommandName Assert-DSCPullServerDatabaseFilePath -MockWith {
                throw 'invalid mdb'
            }

            Mock -CommandName PreProc

            Mock -CommandName Mount-DSCPullServerESEDatabase
            Mock -CommandName Open-DSCPullServerTable
            Mock -CommandName Set-DSCPullServerESERecord
            Mock -CommandName Dismount-DSCPullServerESEDatabase

            { New-DSCPullServerAdminRegistration -AgentId ([guid]::Empty) -ConfigurationNames 'bogusConfig' -NodeName 'bogusNode' -MDBFilePath 'c:\bogus.mdb' 4>&1 } |
                Should -Throw

            Assert-MockCalled -CommandName PreProc -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Get-DSCPullServerAdminRegistration -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerSQLCommand -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Mount-DSCPullServerESEDatabase -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Open-DSCPullServerTable -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Set-DSCPullServerESERecord -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Dismount-DSCPullServerESEDatabase -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerMDBCommand -Exactly -Times 0 -Scope it
        }

        It 'Should create a registration when AgentId specified did not result in registration already found (ESE)' {
            Mock -CommandName Get-DSCPullServerAdminRegistration

            Mock -CommandName Invoke-DSCPullServerSQLCommand

            Mock -CommandName Invoke-DSCPullServerMDBCommand

            Mock -CommandName PreProc -MockWith {
                $eseConnection
            }

            Mock -CommandName Mount-DSCPullServerESEDatabase
            Mock -CommandName Open-DSCPullServerTable
            Mock -CommandName Set-DSCPullServerESERecord
            Mock -CommandName Dismount-DSCPullServerESEDatabase

            New-DSCPullServerAdminRegistration -AgentId ([guid]::Empty) -ConfigurationNames 'bogusConfig' -NodeName 'bogusNode' 4>&1

            Assert-MockCalled -CommandName Get-DSCPullServerAdminRegistration -Exactly -Times 1 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerSQLCommand -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Mount-DSCPullServerESEDatabase -Exactly -Times 1 -Scope it
            Assert-MockCalled -CommandName Open-DSCPullServerTable -Exactly -Times 1 -Scope it
            Assert-MockCalled -CommandName Set-DSCPullServerESERecord -Exactly -Times 1 -Scope it
            Assert-MockCalled -CommandName Dismount-DSCPullServerESEDatabase -Exactly -Times 1 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerMDBCommand -Exactly -Times 0 -Scope it
        }

        It 'Should create a registration when AgentId specified did not result in registration already found and ESEFilePath is used (ESE)' {
            Mock -CommandName Get-DSCPullServerAdminRegistration

            Mock -CommandName Invoke-DSCPullServerSQLCommand

            Mock -CommandName Invoke-DSCPullServerMDBCommand

            Mock -CommandName PreProc -MockWith {
                $eseConnection
            }

            Mock -CommandName Assert-DSCPullServerDatabaseFilePath -MockWith {
                $true
            }

            Mock -CommandName Mount-DSCPullServerESEDatabase
            Mock -CommandName Open-DSCPullServerTable
            Mock -CommandName Set-DSCPullServerESERecord
            Mock -CommandName Dismount-DSCPullServerESEDatabase

            { New-DSCPullServerAdminRegistration -AgentId ([guid]::Empty) -ConfigurationNames 'bogusConfig' -NodeName 'bogusNode' -ESEFilePath 'c:\bogus.edb' 4>&1 } |
                Should -Not -Throw

            Assert-MockCalled -CommandName Get-DSCPullServerAdminRegistration -Exactly -Times 1 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerSQLCommand -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Mount-DSCPullServerESEDatabase -Exactly -Times 1 -Scope it
            Assert-MockCalled -CommandName Open-DSCPullServerTable -Exactly -Times 1 -Scope it
            Assert-MockCalled -CommandName Set-DSCPullServerESERecord -Exactly -Times 1 -Scope it
            Assert-MockCalled -CommandName Dismount-DSCPullServerESEDatabase -Exactly -Times 1 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerMDBCommand -Exactly -Times 0 -Scope it
        }

        It 'Should thow and not create a registration when ESEFilePath is invalid (ESE)' {
            Mock -CommandName Get-DSCPullServerAdminRegistration

            Mock -CommandName Invoke-DSCPullServerSQLCommand

            Mock -CommandName Invoke-DSCPullServerMDBCommand

            Mock -CommandName PreProc

            Mock -CommandName Assert-DSCPullServerDatabaseFilePath -MockWith {
                throw 'invalid edb'
            }

            Mock -CommandName Mount-DSCPullServerESEDatabase
            Mock -CommandName Open-DSCPullServerTable
            Mock -CommandName Set-DSCPullServerESERecord
            Mock -CommandName Dismount-DSCPullServerESEDatabase

            { New-DSCPullServerAdminRegistration -AgentId ([guid]::Empty) -ConfigurationNames 'bogusConfig' -NodeName 'bogusNode' -ESEFilePath 'c:\bogus.edb' 4>&1 } |
                Should -Throw

            Assert-MockCalled -CommandName PreProc -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Get-DSCPullServerAdminRegistration -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerSQLCommand -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Mount-DSCPullServerESEDatabase -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Open-DSCPullServerTable -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Set-DSCPullServerESERecord -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Dismount-DSCPullServerESEDatabase -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerMDBCommand -Exactly -Times 0 -Scope it
        }

        It 'Should throw when AgentId resulted in existing registration' {
            Mock -CommandName Get-DSCPullServerAdminRegistration -MockWith {
                $registration
            }

            Mock -CommandName Invoke-DSCPullServerSQLCommand

            Mock -CommandName Invoke-DSCPullServerMDBCommand

            Mock -CommandName PreProc -MockWith {
                $sqlConnection
            }

            Mock -CommandName Mount-DSCPullServerESEDatabase
            Mock -CommandName Open-DSCPullServerTable
            Mock -CommandName Set-DSCPullServerESERecord
            Mock -CommandName Dismount-DSCPullServerESEDatabase

            { New-DSCPullServerAdminRegistration -AgentId ([guid]::Empty) -ConfigurationNames 'bogusConfig' -NodeName 'bogusNode' } |
                Should -Throw

            Assert-MockCalled -CommandName Get-DSCPullServerAdminRegistration -Exactly -Times 1 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerSQLCommand -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Mount-DSCPullServerESEDatabase -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Open-DSCPullServerTable -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Set-DSCPullServerESERecord -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Dismount-DSCPullServerESEDatabase -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerMDBCommand -Exactly -Times 0 -Scope it
        }

        It 'Should have ShouldProcess before calling Invoke-DSCPullServerSQLCommand' {
            Mock -CommandName Get-DSCPullServerAdminRegistration
        
            Mock -CommandName Invoke-DSCPullServerSQLCommand

            Mock -CommandName Invoke-DSCPullServerMDBCommand

            Mock -CommandName PreProc -MockWith {
                $sqlConnection
            }

            Mock -CommandName Mount-DSCPullServerESEDatabase
            Mock -CommandName Open-DSCPullServerTable
            Mock -CommandName Set-DSCPullServerESERecord
            Mock -CommandName Dismount-DSCPullServerESEDatabase
        
            New-DSCPullServerAdminRegistration -AgentId ([guid]::Empty) -ConfigurationNames 'bogusConfig' -NodeName 'bogusNode' -Connection $sqlConnection -WhatIf
        
            Assert-MockCalled -CommandName Get-DSCPullServerAdminRegistration -Exactly -Times 1 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerSQLCommand -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Mount-DSCPullServerESEDatabase -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Open-DSCPullServerTable -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Set-DSCPullServerESERecord -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Dismount-DSCPullServerESEDatabase -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerMDBCommand -Exactly -Times 0 -Scope it
        }

        It 'Should have ShouldProcess before calling Invoke-DSCPullServerMDBCommand' {
            Mock -CommandName Get-DSCPullServerAdminRegistration
        
            Mock -CommandName Invoke-DSCPullServerSQLCommand

            Mock -CommandName Invoke-DSCPullServerMDBCommand

            Mock -CommandName PreProc -MockWith {
                $mdbConnection
            }

            Mock -CommandName Mount-DSCPullServerESEDatabase
            Mock -CommandName Open-DSCPullServerTable
            Mock -CommandName Set-DSCPullServerESERecord
            Mock -CommandName Dismount-DSCPullServerESEDatabase
        
            New-DSCPullServerAdminRegistration -AgentId ([guid]::Empty) -ConfigurationNames 'bogusConfig' -NodeName 'bogusNode' -Connection $mdbConnection -WhatIf
        
            Assert-MockCalled -CommandName Get-DSCPullServerAdminRegistration -Exactly -Times 1 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerSQLCommand -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Mount-DSCPullServerESEDatabase -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Open-DSCPullServerTable -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Set-DSCPullServerESERecord -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Dismount-DSCPullServerESEDatabase -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerMDBCommand -Exactly -Times 0 -Scope it
        }

        It 'Should have ShouldProcess before calling Set-DSCPullServerESERecord' {
            Mock -CommandName Get-DSCPullServerAdminRegistration
        
            Mock -CommandName Invoke-DSCPullServerSQLCommand

            Mock -CommandName Invoke-DSCPullServerMDBCommand

            Mock -CommandName PreProc -MockWith {
                $eseConnection
            }

            Mock -CommandName Mount-DSCPullServerESEDatabase
            Mock -CommandName Open-DSCPullServerTable
            Mock -CommandName Set-DSCPullServerESERecord
            Mock -CommandName Dismount-DSCPullServerESEDatabase
        
            New-DSCPullServerAdminRegistration -AgentId ([guid]::Empty) -ConfigurationNames 'bogusConfig' -NodeName 'bogusNode' -Connection $eseConnection -WhatIf
        
            Assert-MockCalled -CommandName Get-DSCPullServerAdminRegistration -Exactly -Times 1 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerSQLCommand -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Mount-DSCPullServerESEDatabase -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Open-DSCPullServerTable -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Set-DSCPullServerESERecord -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Dismount-DSCPullServerESEDatabase -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerMDBCommand -Exactly -Times 0 -Scope it
        }

        It 'Should throw and dismount ESE Database when something goes wrong in DB operations' {
            Mock -CommandName Get-DSCPullServerAdminRegistration

            Mock -CommandName Invoke-DSCPullServerSQLCommand

            Mock -CommandName Invoke-DSCPullServerMDBCommand

            Mock -CommandName PreProc -MockWith {
                $eseConnection
            }

            Mock -CommandName Write-Error

            Mock -CommandName Mount-DSCPullServerESEDatabase
            Mock -CommandName Open-DSCPullServerTable -MockWith {
                throw 'Error opening Table'
            }
            Mock -CommandName Set-DSCPullServerESERecord
            Mock -CommandName Dismount-DSCPullServerESEDatabase

            New-DSCPullServerAdminRegistration -AgentId ([guid]::Empty) -ConfigurationNames 'bogusConfig' -NodeName 'bogusNode' 4>&1

            Assert-MockCalled -CommandName Get-DSCPullServerAdminRegistration -Exactly -Times 1 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerSQLCommand -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Mount-DSCPullServerESEDatabase -Exactly -Times 1 -Scope it
            Assert-MockCalled -CommandName Open-DSCPullServerTable -Exactly -Times 1 -Scope it
            Assert-MockCalled -CommandName Set-DSCPullServerESERecord -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Dismount-DSCPullServerESEDatabase -Exactly -Times 1 -Scope it
            Assert-MockCalled -CommandName Write-Error -Exactly -Times 1 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerMDBCommand -Exactly -Times 0 -Scope it
        }
    }
}
