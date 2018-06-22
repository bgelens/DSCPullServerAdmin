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

    Describe New-DSCPullServerAdminDevice {
        Mock -CommandName PreProc -MockWith {
            $sqlConnection
        }

        It 'Should create a device when TargetName specified did not result in device already found' {
            Mock -CommandName Get-DSCPullServerAdminDevice

            Mock -CommandName Invoke-DSCPullServerSQLCommand -MockWith {
                param (
                    $script
                )
                Write-Verbose -Message $Script -Verbose
            }

            New-DSCPullServerAdminDevice -TargetName 'bogusDevice' -ConfigurationID ([guid]::Empty) -Confirm:$false 4>&1

            Assert-MockCalled -CommandName Get-DSCPullServerAdminDevice -Exactly -Times 1 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerSQLCommand -Exactly -Times 1 -Scope it
        }

        It 'Should throw when TargetName resulted in existing device' {
            Mock -CommandName Get-DSCPullServerAdminDevice -MockWith {
                $device
            }

            Mock -CommandName Invoke-DSCPullServerSQLCommand

            { New-DSCPullServerAdminDevice -TargetName 'bogusDevice' -ConfigurationID ([guid]::Empty) } |
                Should -Throw

            Assert-MockCalled -CommandName Get-DSCPullServerAdminDevice -Exactly -Times 1 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerSQLCommand -Exactly -Times 0 -Scope it
        }

        It 'Should have ShouldProcess before calling Invoke-DSCPullServerSQLCommand' {
            Mock -CommandName Get-DSCPullServerAdminDevice
        
            Mock -CommandName Invoke-DSCPullServerSQLCommand
        
            New-DSCPullServerAdminDevice -TargetName 'bogusDevice' -ConfigurationID ([guid]::Empty) -WhatIf
        
            Assert-MockCalled -CommandName Get-DSCPullServerAdminDevice -Exactly -Times 1 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerSQLCommand -Exactly -Times 0 -Scope it
        }
    }
}
