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

    $device = [DSCDevice]::new()
    $device.TargetName = 'bogusDevice'
    $device.ConfigurationID = ([guid]::Empty)

    function GetDeviceFromEDB {
        $script:GetConnection = $eseConnection
        $device
    }

    Describe Set-DSCPullServerAdminDevice {
        It 'Should update a device when it is passed in via InputObject (pipeline) SQL' {
            Mock -CommandName Get-DSCPullServerAdminDevice

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

            $result = $device | Set-DSCPullServerAdminDevice -ConfigurationID '00000000-0000-0000-0000-000000000001' -Confirm:$false 4>&1
            $result | Should -Not -BeNullOrEmpty

            Assert-MockCalled -CommandName Get-DSCPullServerAdminDevice -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerSQLCommand -Exactly -Times 1 -Scope it
            Assert-MockCalled -CommandName Set-DSCPullServerESERecord -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerMDBCommand -Exactly -Times 0 -Scope it
        }

        It 'Should update a device when it is passed in via InputObject (pipeline) MDB' {
            Mock -CommandName Get-DSCPullServerAdminDevice

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

            $result = $device | Set-DSCPullServerAdminDevice -ConfigurationID '00000000-0000-0000-0000-000000000001' -Confirm:$false 4>&1
            $result | Should -Not -BeNullOrEmpty

            Assert-MockCalled -CommandName Get-DSCPullServerAdminDevice -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerSQLCommand -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Set-DSCPullServerESERecord -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerMDBCommand -Exactly -Times 1 -Scope it
        }

        It 'Should update a device when it is passed in via InputObject (pipeline) ESE' {
            Mock -CommandName Get-DSCPullServerAdminDevice

            Mock -CommandName Invoke-DSCPullServerSQLCommand

            Mock -CommandName Invoke-DSCPullServerMDBCommand

            Mock -CommandName Set-DSCPullServerESERecord

            Mock -CommandName PreProc -MockWith {
                $eseConnection
            }

            GetDeviceFromEDB | Set-DSCPullServerAdminDevice -ConfigurationID '00000000-0000-0000-0000-000000000001' -Confirm:$false 4>&1

            Assert-MockCalled -CommandName Get-DSCPullServerAdminDevice -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerSQLCommand -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Set-DSCPullServerESERecord -Exactly -Times 1 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerMDBCommand -Exactly -Times 0 -Scope it
        }

        It 'Should update a device when TargetName was specified and device was found (SQL)' {
            Mock -CommandName Get-DSCPullServerAdminDevice -MockWith {
                $device
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

            $result = Set-DSCPullServerAdminDevice -TargetName 'bogusDevice' -ConfigurationID '00000000-0000-0000-0000-000000000001' -Connection $sqlConnection -Confirm:$false 4>&1
            $result | Should -Not -BeNullOrEmpty

            Assert-MockCalled -CommandName Get-DSCPullServerAdminDevice -Exactly -Times 1 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerSQLCommand -Exactly -Times 1 -Scope it
            Assert-MockCalled -CommandName Set-DSCPullServerESERecord -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerMDBCommand -Exactly -Times 0 -Scope it
        }

        It 'Should update a device when TargetName was specified and device was found (MDB)' {
            Mock -CommandName Get-DSCPullServerAdminDevice -MockWith {
                $device
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

            $result = Set-DSCPullServerAdminDevice -TargetName 'bogusDevice' -ConfigurationID '00000000-0000-0000-0000-000000000001' -Connection $mdbConnection -Confirm:$false 4>&1
            $result | Should -Not -BeNullOrEmpty

            Assert-MockCalled -CommandName Get-DSCPullServerAdminDevice -Exactly -Times 1 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerSQLCommand -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Set-DSCPullServerESERecord -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerMDBCommand -Exactly -Times 1 -Scope it
        }

        It 'Should update a device when TargetName was specified and device was found and MDBFilePath is used (MDB)' {
            Mock -CommandName Get-DSCPullServerAdminDevice -MockWith {
                $device
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

            { Set-DSCPullServerAdminDevice -TargetName 'bogusDevice' -ConfigurationID '00000000-0000-0000-0000-000000000001' -MDBFilePath 'c:\bogus.mdb' -Confirm:$false 4>&1 } |
                Should -Not -Throw


            Assert-MockCalled -CommandName Get-DSCPullServerAdminDevice -Exactly -Times 1 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerSQLCommand -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Set-DSCPullServerESERecord -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerMDBCommand -Exactly -Times 1 -Scope it
        }

        It 'Should not update a device when MDBFilePath is invalid (MDB)' {
            Mock -CommandName Get-DSCPullServerAdminDevice

            Mock -CommandName Invoke-DSCPullServerSQLCommand

            Mock -CommandName Invoke-DSCPullServerMDBCommand

            Mock -CommandName Set-DSCPullServerESERecord

            Mock -CommandName PreProc -MockWith {
                $mdbConnection
            }

            Mock -CommandName Assert-DSCPullServerDatabaseFilePath -MockWith {
                throw 'invalid mdb'
            }

            { Set-DSCPullServerAdminDevice -TargetName 'bogusDevice' -ConfigurationID '00000000-0000-0000-0000-000000000001' -MDBFilePath 'c:\bogus.mdb' -Confirm:$false 4>&1 } |
                Should -Throw

            Assert-MockCalled -CommandName PreProc -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Get-DSCPullServerAdminDevice -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerSQLCommand -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Set-DSCPullServerESERecord -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerMDBCommand -Exactly -Times 0 -Scope it
        }

        It 'Should update a device when TargetName was specified and device was found (ESE)' {
            Mock -CommandName Get-DSCPullServerAdminDevice -MockWith {
                $device
            }

            Mock -CommandName Invoke-DSCPullServerSQLCommand

            Mock -CommandName Invoke-DSCPullServerMDBCommand

            Mock -CommandName Set-DSCPullServerESERecord

            Mock -CommandName PreProc -MockWith {
                $eseConnection
            }

            Set-DSCPullServerAdminDevice -TargetName 'bogusDevice' -ConfigurationID '00000000-0000-0000-0000-000000000001' -Connection $eseConnection -Confirm:$false 4>&1

            Assert-MockCalled -CommandName Get-DSCPullServerAdminDevice -Exactly -Times 2 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerSQLCommand -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Set-DSCPullServerESERecord -Exactly -Times 1 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerMDBCommand -Exactly -Times 0 -Scope it
        }

        It 'Should update a device when TargetName was specified and device was found and ESEFilePath is used (ESE)' {
            Mock -CommandName Get-DSCPullServerAdminDevice -MockWith {
                $device
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

            { Set-DSCPullServerAdminDevice -TargetName 'bogusDevice' -ConfigurationID '00000000-0000-0000-0000-000000000001' -ESEFilePath 'c:\bogus.edb' -Confirm:$false 4>&1 } |
                Should -Not -Throw

            Assert-MockCalled -CommandName Get-DSCPullServerAdminDevice -Exactly -Times 2 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerSQLCommand -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Set-DSCPullServerESERecord -Exactly -Times 1 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerMDBCommand -Exactly -Times 0 -Scope it
        }

        It 'Should not update a device when ESEFilePath is invalid (ESE)' {
            Mock -CommandName Get-DSCPullServerAdminDevice

            Mock -CommandName Invoke-DSCPullServerSQLCommand

            Mock -CommandName Invoke-DSCPullServerMDBCommand

            Mock -CommandName Set-DSCPullServerESERecord

            Mock -CommandName PreProc
            
            Mock -CommandName Assert-DSCPullServerDatabaseFilePath -MockWith {
                throw 'invalid edb'
            }

            { Set-DSCPullServerAdminDevice -TargetName 'bogusDevice' -ConfigurationID '00000000-0000-0000-0000-000000000001' -ESEFilePath 'c:\bogus.edb' -Confirm:$false 4>&1 } |
                Should -Throw

            Assert-MockCalled -CommandName PreProc -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Get-DSCPullServerAdminDevice -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerSQLCommand -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Set-DSCPullServerESERecord -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerMDBCommand -Exactly -Times 0 -Scope it
        }

        It 'Should throw when TargetName was specified but device was not found (SQL)' {
            Mock -CommandName Get-DSCPullServerAdminDevice

            Mock -CommandName Invoke-DSCPullServerSQLCommand

            Mock -CommandName Invoke-DSCPullServerMDBCommand

            Mock -CommandName Set-DSCPullServerESERecord

            Mock -CommandName PreProc -MockWith {
                $sqlConnection
            }

            { Set-DSCPullServerAdminDevice -TargetName 'bogusDevice' -ConfigurationID '00000000-0000-0000-0000-000000000001' -Confirm:$false } |
                Should -Throw

            Assert-MockCalled -CommandName Get-DSCPullServerAdminDevice -Exactly -Times 1 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerSQLCommand -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Set-DSCPullServerESERecord -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerMDBCommand -Exactly -Times 0 -Scope it
        }

        It 'Should throw when TargetName was specified but device was not found (MDB)' {
            Mock -CommandName Get-DSCPullServerAdminDevice

            Mock -CommandName Invoke-DSCPullServerSQLCommand

            Mock -CommandName Invoke-DSCPullServerMDBCommand

            Mock -CommandName Set-DSCPullServerESERecord

            Mock -CommandName PreProc -MockWith {
                $mdbConnection
            }

            { Set-DSCPullServerAdminDevice -TargetName 'bogusDevice' -ConfigurationID '00000000-0000-0000-0000-000000000001' -Confirm:$false } |
                Should -Throw

            Assert-MockCalled -CommandName Get-DSCPullServerAdminDevice -Exactly -Times 1 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerSQLCommand -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Set-DSCPullServerESERecord -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerMDBCommand -Exactly -Times 0 -Scope it
        }

        It 'Should throw when TargetName was specified but device was not found (ESE)' {
            Mock -CommandName Get-DSCPullServerAdminDevice

            Mock -CommandName Invoke-DSCPullServerSQLCommand

            Mock -CommandName Invoke-DSCPullServerMDBCommand

            Mock -CommandName Set-DSCPullServerESERecord

            Mock -CommandName PreProc -MockWith {
                $eseConnection
            }

            { Set-DSCPullServerAdminDevice -TargetName 'bogusDevice' -ConfigurationID '00000000-0000-0000-0000-000000000001' -Confirm:$false } |
                Should -Throw

            Assert-MockCalled -CommandName Get-DSCPullServerAdminDevice -Exactly -Times 1 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerSQLCommand -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Set-DSCPullServerESERecord -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerMDBCommand -Exactly -Times 0 -Scope it
        }

        It 'Should have ShouldProcess before calling Invoke-DSCPullServerSQLCommand' {
            Mock -CommandName Get-DSCPullServerAdminDevice

            Mock -CommandName Invoke-DSCPullServerSQLCommand

            Mock -CommandName Invoke-DSCPullServerMDBCommand

            Mock -CommandName Set-DSCPullServerESERecord

            Mock -CommandName PreProc -MockWith {
                $sqlConnection
            }

            $device | Set-DSCPullServerAdminDevice -ConfigurationID '00000000-0000-0000-0000-000000000001' -WhatIf

            Assert-MockCalled -CommandName Get-DSCPullServerAdminDevice -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerSQLCommand -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Set-DSCPullServerESERecord -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerMDBCommand -Exactly -Times 0 -Scope it
        }

        It 'Should have ShouldProcess before calling Invoke-DSCPullServerMDBCommand' {
            Mock -CommandName Get-DSCPullServerAdminDevice

            Mock -CommandName Invoke-DSCPullServerSQLCommand

            Mock -CommandName Invoke-DSCPullServerMDBCommand

            Mock -CommandName Set-DSCPullServerESERecord

            Mock -CommandName PreProc -MockWith {
                $mdbConnection
            }

            $device | Set-DSCPullServerAdminDevice -ConfigurationID '00000000-0000-0000-0000-000000000001' -WhatIf

            Assert-MockCalled -CommandName Get-DSCPullServerAdminDevice -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerSQLCommand -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Set-DSCPullServerESERecord -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerMDBCommand -Exactly -Times 0 -Scope it
        }

        It 'Should have ShouldProcess before calling Set-DSCPullServerESERecord' {
            Mock -CommandName Get-DSCPullServerAdminDevice

            Mock -CommandName Invoke-DSCPullServerSQLCommand

            Mock -CommandName Invoke-DSCPullServerMDBCommand

            Mock -CommandName Set-DSCPullServerESERecord

            Mock -CommandName PreProc -MockWith {
                $eseConnection
            }

            $device | Set-DSCPullServerAdminDevice -ConfigurationID '00000000-0000-0000-0000-000000000001' -WhatIf

            Assert-MockCalled -CommandName Get-DSCPullServerAdminDevice -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerSQLCommand -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Set-DSCPullServerESERecord -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerMDBCommand -Exactly -Times 0 -Scope it
        }
    }
}
