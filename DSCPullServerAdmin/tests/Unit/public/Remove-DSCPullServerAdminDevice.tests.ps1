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

    $device = [DSCDevice]::new()
    $device.TargetName = 'bogusDevice'

    function GetDeviceFromEDB {
        $script:GetConnection = $eseConnection
        $device
    }

    Describe Remove-DSCPullServerAdminDevice {
        It 'Should remove a device when it is passed in via InputObject (pipeline) SQL' {
            Mock -CommandName Get-DSCPullServerAdminDevice

            Mock -CommandName Invoke-DSCPullServerSQLCommand -MockWith {
                param (
                    $script
                )
                Write-Verbose -Message $Script -Verbose
            }

            Mock -CommandName Invoke-DSCPullServerMDBCommand

            Mock -CommandName Remove-DSCPullServerESERecord

            Mock -CommandName PreProc -MockWith {
                $sqlConnection
            }

            $result = $device | Remove-DSCPullServerAdminDevice -Confirm:$false 4>&1
            $result | Should -Not -BeNullOrEmpty

            Assert-MockCalled -CommandName Get-DSCPullServerAdminDevice -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerSQLCommand -Exactly -Times 1 -Scope it
            Assert-MockCalled -CommandName Remove-DSCPullServerESERecord -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerMDBCommand -Exactly -Times 0 -Scope it
        }

        It 'Should remove a device when it is passed in via InputObject (pipeline) MDB' {
            Mock -CommandName Get-DSCPullServerAdminDevice

            Mock -CommandName Invoke-DSCPullServerSQLCommand

            Mock -CommandName Invoke-DSCPullServerMDBCommand -MockWith {
                param (
                    $script
                )
                Write-Verbose -Message $Script -Verbose
            }

            Mock -CommandName Remove-DSCPullServerESERecord

            Mock -CommandName PreProc -MockWith {
                $mdbConnection
            }

            $result = $device | Remove-DSCPullServerAdminDevice -Confirm:$false 4>&1
            $result | Should -Not -BeNullOrEmpty

            Assert-MockCalled -CommandName Get-DSCPullServerAdminDevice -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerSQLCommand -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Remove-DSCPullServerESERecord -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerMDBCommand -Exactly -Times 1 -Scope it
        }

        It 'Should remove a device when it is passed in via InputObject (pipeline) ESE' {
            Mock -CommandName Get-DSCPullServerAdminDevice

            Mock -CommandName Invoke-DSCPullServerSQLCommand

            Mock -CommandName Invoke-DSCPullServerMDBCommand

            Mock -CommandName Remove-DSCPullServerESERecord

            Mock -CommandName PreProc -MockWith {
                $eseConnection
            }

            GetDeviceFromEDB | Remove-DSCPullServerAdminDevice -Confirm:$false 4>&1

            Assert-MockCalled -CommandName Get-DSCPullServerAdminDevice -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerSQLCommand -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Remove-DSCPullServerESERecord -Exactly -Times 1 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerMDBCommand -Exactly -Times 0 -Scope it
        }

        It 'Should remove a device when TargetName was specified and device was found (SQL)' {
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

            Mock -CommandName Remove-DSCPullServerESERecord

            Mock -CommandName PreProc -MockWith {
                $sqlConnection
            }

            $result = Remove-DSCPullServerAdminDevice -TargetName 'bogusDevice' -Connection $sqlConnection -Confirm:$false 4>&1
            $result | Should -Not -BeNullOrEmpty

            Assert-MockCalled -CommandName Get-DSCPullServerAdminDevice -Exactly -Times 1 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerSQLCommand -Exactly -Times 1 -Scope it
            Assert-MockCalled -CommandName Remove-DSCPullServerESERecord -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerMDBCommand -Exactly -Times 0 -Scope it
        }

        It 'Should remove a device when TargetName was specified and device was found (MDB)' {
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

            Mock -CommandName Remove-DSCPullServerESERecord

            Mock -CommandName PreProc -MockWith {
                $mdbConnection
            }

            $result = Remove-DSCPullServerAdminDevice -TargetName 'bogusDevice' -Connection $mdbConnection -Confirm:$false 4>&1
            $result | Should -Not -BeNullOrEmpty

            Assert-MockCalled -CommandName Get-DSCPullServerAdminDevice -Exactly -Times 1 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerSQLCommand -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Remove-DSCPullServerESERecord -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerMDBCommand -Exactly -Times 1 -Scope it
        }

        It 'Should remove a device when TargetName was specified and device was found and MDBFilePath is used (MDB)' {
            Mock -CommandName Get-DSCPullServerAdminDevice -MockWith {
                $device
            }

            Mock -CommandName Invoke-DSCPullServerSQLCommand

            Mock -CommandName Invoke-DSCPullServerMDBCommand

            Mock -CommandName Remove-DSCPullServerESERecord

            Mock -CommandName PreProc -MockWith {
                $mdbConnection
            }

            Mock -CommandName Assert-DSCPullServerDatabaseFilePath -MockWith {
                $true
            }

            { Remove-DSCPullServerAdminDevice -TargetName 'bogusDevice' -MDBFilePath 'c:\bogus.mdb' -Confirm:$false 4>&1 } |
                Should -Not -Throw

            Assert-MockCalled -CommandName Get-DSCPullServerAdminDevice -Exactly -Times 1 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerSQLCommand -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Remove-DSCPullServerESERecord -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerMDBCommand -Exactly -Times 1 -Scope it
        }

        It 'Should throw and not remove a device when MDBFilePath is invalid (MDB)' {
            Mock -CommandName Get-DSCPullServerAdminDevice -MockWith {
                $device
            }

            Mock -CommandName Invoke-DSCPullServerSQLCommand

            Mock -CommandName Invoke-DSCPullServerMDBCommand

            Mock -CommandName Remove-DSCPullServerESERecord

            Mock -CommandName PreProc

            Mock -CommandName Assert-DSCPullServerDatabaseFilePath -MockWith {
                throw 'invalid mdb'
            }

            { Remove-DSCPullServerAdminDevice -TargetName 'bogusDevice' -MDBFilePath 'c:\bogus.mdb' -Confirm:$false 4>&1 } |
                Should -Throw

            Assert-MockCalled -CommandName PreProc -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Get-DSCPullServerAdminDevice -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerSQLCommand -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Remove-DSCPullServerESERecord -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerMDBCommand -Exactly -Times 0 -Scope it
        }

        It 'Should remove a device when TargetName was specified and device was found (ESE)' {
            Mock -CommandName Get-DSCPullServerAdminDevice -MockWith {
                $device
            }

            Mock -CommandName Invoke-DSCPullServerSQLCommand

            Mock -CommandName Invoke-DSCPullServerMDBCommand

            Mock -CommandName Remove-DSCPullServerESERecord

            Mock -CommandName PreProc -MockWith {
                $eseConnection
            }

            Remove-DSCPullServerAdminDevice -TargetName 'bogusDevice' -Connection $eseConnection -Confirm:$false 4>&1

            Assert-MockCalled -CommandName Get-DSCPullServerAdminDevice -Exactly -Times 2 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerSQLCommand -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Remove-DSCPullServerESERecord -Exactly -Times 1 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerMDBCommand -Exactly -Times 0 -Scope it
        }

        It 'Should remove a device when TargetName was specified and device was found and ESEFilePath is used (ESE)' {
            Mock -CommandName Get-DSCPullServerAdminDevice -MockWith {
                $device
            }

            Mock -CommandName Invoke-DSCPullServerSQLCommand

            Mock -CommandName Invoke-DSCPullServerMDBCommand

            Mock -CommandName Remove-DSCPullServerESERecord

            Mock -CommandName PreProc -MockWith {
                $eseConnection
            }

            Mock -CommandName Assert-DSCPullServerDatabaseFilePath -MockWith {
                $true
            }

            { Remove-DSCPullServerAdminDevice -TargetName 'bogusDevice' -ESEFilePath 'c:\bogus.edb' -Confirm:$false 4>&1 } |
                Should -Not -Throw

            Assert-MockCalled -CommandName Get-DSCPullServerAdminDevice -Exactly -Times 2 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerSQLCommand -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Remove-DSCPullServerESERecord -Exactly -Times 1 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerMDBCommand -Exactly -Times 0 -Scope it
        }

        It 'Should throw and not remove a device when ESEFilePath is invalid (ESE)' {
            Mock -CommandName Get-DSCPullServerAdminDevice -MockWith {
                $device
            }

            Mock -CommandName Invoke-DSCPullServerSQLCommand

            Mock -CommandName Invoke-DSCPullServerMDBCommand

            Mock -CommandName Remove-DSCPullServerESERecord

            Mock -CommandName PreProc
            Mock -CommandName Assert-DSCPullServerDatabaseFilePath -MockWith {
                throw 'invalid edb'
            }

            { Remove-DSCPullServerAdminDevice -TargetName 'bogusDevice' -ESEFilePath 'c:\bogus.edb' -Confirm:$false 4>&1 } |
                Should -Throw

            Assert-MockCalled -CommandName Get-DSCPullServerAdminDevice -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerSQLCommand -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Remove-DSCPullServerESERecord -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerMDBCommand -Exactly -Times 0 -Scope it
        }

        It 'Should write a warning when TargetName was specified but device was not found (SQL)' {
            Mock -CommandName Get-DSCPullServerAdminDevice

            Mock -CommandName Invoke-DSCPullServerSQLCommand

            Mock -CommandName Invoke-DSCPullServerMDBCommand

            Mock -CommandName Write-Warning

            Mock -CommandName Remove-DSCPullServerESERecord

            Mock -CommandName PreProc -MockWith {
                $sqlConnection
            }

            Remove-DSCPullServerAdminDevice -TargetName 'bogusDevice'

            Assert-MockCalled -CommandName Get-DSCPullServerAdminDevice -Exactly -Times 1 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerSQLCommand -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Write-Warning -Exactly -Times 1 -Scope it
            Assert-MockCalled -CommandName Remove-DSCPullServerESERecord -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerMDBCommand -Exactly -Times 0 -Scope it
        }

        It 'Should write a warning when TargetName was specified but device was not found (MDB)' {
            Mock -CommandName Get-DSCPullServerAdminDevice

            Mock -CommandName Invoke-DSCPullServerSQLCommand

            Mock -CommandName Invoke-DSCPullServerMDBCommand

            Mock -CommandName Write-Warning

            Mock -CommandName Remove-DSCPullServerESERecord

            Mock -CommandName PreProc -MockWith {
                $mdbConnection
            }

            Remove-DSCPullServerAdminDevice -TargetName 'bogusDevice'

            Assert-MockCalled -CommandName Get-DSCPullServerAdminDevice -Exactly -Times 1 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerSQLCommand -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Write-Warning -Exactly -Times 1 -Scope it
            Assert-MockCalled -CommandName Remove-DSCPullServerESERecord -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerMDBCommand -Exactly -Times 0 -Scope it
        }

        It 'Should write a warning when TargetName was specified but device was not found (ESE)' {
            Mock -CommandName Get-DSCPullServerAdminDevice

            Mock -CommandName Invoke-DSCPullServerSQLCommand

            Mock -CommandName Invoke-DSCPullServerMDBCommand

            Mock -CommandName Write-Warning

            Mock -CommandName Remove-DSCPullServerESERecord

            Mock -CommandName PreProc -MockWith {
                $eseConnection
            }

            Remove-DSCPullServerAdminDevice -TargetName 'bogusDevice'

            Assert-MockCalled -CommandName Get-DSCPullServerAdminDevice -Exactly -Times 1 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerSQLCommand -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Write-Warning -Exactly -Times 1 -Scope it
            Assert-MockCalled -CommandName Remove-DSCPullServerESERecord -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerMDBCommand -Exactly -Times 0 -Scope it
        }

        It 'Should have ShouldProcess before calling Invoke-DSCPullServerSQLCommand' {
            Mock -CommandName Get-DSCPullServerAdminDevice

            Mock -CommandName Invoke-DSCPullServerSQLCommand

            Mock -CommandName Invoke-DSCPullServerMDBCommand

            Mock -CommandName Remove-DSCPullServerESERecord

            Mock -CommandName PreProc -MockWith {
                $sqlConnection
            }

            $device | Remove-DSCPullServerAdminDevice -WhatIf

            Assert-MockCalled -CommandName Get-DSCPullServerAdminDevice -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerSQLCommand -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Remove-DSCPullServerESERecord -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerMDBCommand -Exactly -Times 0 -Scope it
        }

        It 'Should have ShouldProcess before calling Invoke-DSCPullServerMDBCommand' {
            Mock -CommandName Get-DSCPullServerAdminDevice

            Mock -CommandName Invoke-DSCPullServerSQLCommand

            Mock -CommandName Invoke-DSCPullServerMDBCommand

            Mock -CommandName Remove-DSCPullServerESERecord

            Mock -CommandName PreProc -MockWith {
                $mdbConnection
            }

            $device | Remove-DSCPullServerAdminDevice -WhatIf

            Assert-MockCalled -CommandName Get-DSCPullServerAdminDevice -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerSQLCommand -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Remove-DSCPullServerESERecord -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerMDBCommand -Exactly -Times 0 -Scope it
        }

        It 'Should have ShouldProcess before calling Remove-DSCPullServerESERecord' {
            Mock -CommandName Get-DSCPullServerAdminDevice

            Mock -CommandName Invoke-DSCPullServerSQLCommand

            Mock -CommandName Invoke-DSCPullServerMDBCommand

            Mock -CommandName Remove-DSCPullServerESERecord

            Mock -CommandName PreProc -MockWith {
                $eseConnection
            }

            $device | Remove-DSCPullServerAdminDevice -WhatIf

            Assert-MockCalled -CommandName Get-DSCPullServerAdminDevice -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerSQLCommand -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Remove-DSCPullServerESERecord -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerMDBCommand -Exactly -Times 0 -Scope it
        }
    }
}
