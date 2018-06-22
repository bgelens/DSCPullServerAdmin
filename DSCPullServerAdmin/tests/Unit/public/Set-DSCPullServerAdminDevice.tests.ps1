$here = $PSScriptRoot

$modulePath = "$here\..\..\.."
$moduleName = Split-Path -Path $modulePath -Leaf

InModuleScope $moduleName {
    $sqlConnection = [DSCPullServerSQLConnection]::new()
    $sqlConnection.Active = $true
    $sqlConnection.Index = 0

    $script:DSCPullServerConnections = [System.Collections.ArrayList]::new()
    [void] $script:DSCPullServerConnections.Add($sqlConnection)

    $device = [DSCDevice]::new()
    $device.TargetName = 'bogusDevice'
    $device.ConfigurationID = ([guid]::Empty)

    Describe Set-DSCPullServerAdminDevice {
        Mock -CommandName PreProc -MockWith {
            $sqlConnection
        }

        It 'Should update a device when it is passed in via InputObject (pipeline)' {
            Mock -CommandName Get-DSCPullServerAdminDevice

            Mock -CommandName Invoke-DSCPullServerSQLCommand -MockWith {
                param (
                    $script
                )
                Write-Verbose -Message $Script -Verbose
            }

            $result = $device | Set-DSCPullServerAdminDevice -ConfigurationID '00000000-0000-0000-0000-000000000001' 4>&1
            $result | Should -Not -BeNullOrEmpty

            Assert-MockCalled -CommandName Get-DSCPullServerAdminDevice -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerSQLCommand -Exactly -Times 1 -Scope it
        }

        It 'Should update a device when TargetName was specified and device was found' {
            Mock -CommandName Get-DSCPullServerAdminDevice -MockWith {
                $device
            }

            Mock -CommandName Invoke-DSCPullServerSQLCommand -MockWith {
                param (
                    $script
                )
                Write-Verbose -Message $Script -Verbose
            }

            $result = Set-DSCPullServerAdminDevice -TargetName 'bogusDevice' -ConfigurationID '00000000-0000-0000-0000-000000000001' 4>&1
            $result | Should -Not -BeNullOrEmpty

            Assert-MockCalled -CommandName Get-DSCPullServerAdminDevice -Exactly -Times 1 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerSQLCommand -Exactly -Times 1 -Scope it
        }

        It 'Should throw when TargetName was specified but device was not found' {
            Mock -CommandName Get-DSCPullServerAdminDevice

            Mock -CommandName Invoke-DSCPullServerSQLCommand

            { Set-DSCPullServerAdminDevice -TargetName 'bogusDevice' -ConfigurationID '00000000-0000-0000-0000-000000000001' } |
                Should -Throw

            Assert-MockCalled -CommandName Get-DSCPullServerAdminDevice -Exactly -Times 1 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerSQLCommand -Exactly -Times 0 -Scope it
        }

        It 'Should have ShouldProcess before calling Invoke-DSCPullServerSQLCommand' {
            Mock -CommandName Get-DSCPullServerAdminDevice
        
            Mock -CommandName Invoke-DSCPullServerSQLCommand
        
            $device | Set-DSCPullServerAdminDevice -ConfigurationID '00000000-0000-0000-0000-000000000001' -WhatIf
        
            Assert-MockCalled -CommandName Get-DSCPullServerAdminDevice -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerSQLCommand -Exactly -Times 0 -Scope it
        }
    }
}
