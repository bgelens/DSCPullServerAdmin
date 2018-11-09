$here = $PSScriptRoot

$modulePath = "$here\..\..\.."
$moduleName = Split-Path -Path $modulePath -Leaf

InModuleScope $moduleName {
    $eseConnection = [DSCPullServerESEConnection]::new()
    $eseConnection.Index = 1

    $sqlConnection = [DSCPullServerSQLConnection]::new()
    $sqlConnection.Active = $true
    $sqlConnection.Index = 0

    $device = [DSCDevice]::new()
    $device.TargetName = 'bogusDevice'
    $device.ConfigurationID = ([guid]::Empty)

    $registration = [DSCNodeRegistration]::new()
    $registration.AgentId = [guid]::Empty

    $report = [DSCNodeStatusReport]::new()
    $report.Id = [guid]::Empty
    $report.JobId = [guid]::Empty

    Describe Copy-DSCPullServerAdminData {
        Context 'Devices' {
            It 'Should Copy devices from ESE to SQL when they do not exist in SQL' {
                Mock -CommandName Get-DSCPullServerAdminDevice -MockWith {
                    param (
                        $Connection
                    )
                    if ($Connection.Type -eq 'ESE') {
                        $device
                    }
                }

                Mock -CommandName Invoke-DSCPullServerSQLCommand -MockWith {
                    param (
                        $Script
                    )
                    Write-Verbose -Message $Script -Verbose
                }

                Mock -CommandName Write-Warning

                $result = Copy-DSCPullServerAdminData -Connection1 $eseConnection -Connection2 $sqlConnection -ObjectsToMigrate Devices 4>&1
                $result | Should -Not -BeNullOrEmpty
                ($result | Measure-Object).Count | Should -BeExactly 1

                Assert-MockCalled -CommandName Get-DSCPullServerAdminDevice -Exactly -Times 2 -Scope it
                Assert-MockCalled -CommandName Invoke-DSCPullServerSQLCommand -Exactly -Times 1 -Scope it
                Assert-MockCalled -CommandName Write-Warning -Exactly -Times 0 -Scope it
            }

            It 'Should write a warning when copying devices from ESE to SQL when they already exist in SQL' {
                Mock -CommandName Get-DSCPullServerAdminDevice -MockWith {
                    $device
                }

                Mock -CommandName Invoke-DSCPullServerSQLCommand -MockWith {
                    param (
                        $Script
                    )
                    Write-Verbose -Message $Script -Verbose
                }

                Mock -CommandName Write-Warning

                $result = Copy-DSCPullServerAdminData -Connection1 $eseConnection -Connection2 $sqlConnection -ObjectsToMigrate Devices 4>&1
                $result | Should -BeNullOrEmpty
                ($result | Measure-Object).Count | Should -BeExactly 0

                Assert-MockCalled -CommandName Get-DSCPullServerAdminDevice -Exactly -Times 2 -Scope it
                Assert-MockCalled -CommandName Invoke-DSCPullServerSQLCommand -Exactly -Times 0 -Scope it
                Assert-MockCalled -CommandName Write-Warning -Exactly -Times 1 -Scope it
            }

            It 'Should overwrite a device when copying devices from ESE to SQL when they already exist in SQL but force switch was used' {
                Mock -CommandName Get-DSCPullServerAdminDevice -MockWith {
                    $device
                }

                Mock -CommandName Invoke-DSCPullServerSQLCommand -MockWith {
                    param (
                        $Script
                    )
                    Write-Verbose -Message $Script -Verbose
                }

                Mock -CommandName Write-Warning

                $result = Copy-DSCPullServerAdminData -Connection1 $eseConnection -Connection2 $sqlConnection -ObjectsToMigrate Devices -Force 4>&1
                $result | Should -Not -BeNullOrEmpty
                ($result | Measure-Object).Count | Should -BeExactly 2

                Assert-MockCalled -CommandName Get-DSCPullServerAdminDevice -Exactly -Times 2 -Scope it
                Assert-MockCalled -CommandName Invoke-DSCPullServerSQLCommand -Exactly -Times 2 -Scope it
                Assert-MockCalled -CommandName Write-Warning -Exactly -Times 0 -Scope it
            }

            It 'Should have ShouldProcess before calling Invoke-DSCPullServerSQLCommand when device does not exist in SQL' {
                Mock -CommandName Get-DSCPullServerAdminDevice -MockWith {
                    param (
                        $Connection
                    )
                    if ($Connection.Type -eq 'ESE') {
                        $device
                    }
                }

                Mock -CommandName Invoke-DSCPullServerSQLCommand

                Mock -CommandName Write-Warning

                Copy-DSCPullServerAdminData -Connection1 $eseConnection -Connection2 $sqlConnection -ObjectsToMigrate Devices -WhatIf

                Assert-MockCalled -CommandName Get-DSCPullServerAdminDevice -Exactly -Times 2 -Scope it
                Assert-MockCalled -CommandName Invoke-DSCPullServerSQLCommand -Exactly -Times 0 -Scope it
                Assert-MockCalled -CommandName Write-Warning -Exactly -Times 0 -Scope it
            }

            It 'Should have ShouldProcess before calling Invoke-DSCPullServerSQLCommand when device already exists in SQL' {
                Mock -CommandName Get-DSCPullServerAdminDevice -MockWith {
                    $device
                }

                Mock -CommandName Invoke-DSCPullServerSQLCommand

                Mock -CommandName Write-Warning

                Copy-DSCPullServerAdminData -Connection1 $eseConnection -Connection2 $sqlConnection -ObjectsToMigrate Devices -WhatIf

                Assert-MockCalled -CommandName Get-DSCPullServerAdminDevice -Exactly -Times 2 -Scope it
                Assert-MockCalled -CommandName Invoke-DSCPullServerSQLCommand -Exactly -Times 0 -Scope it
                Assert-MockCalled -CommandName Write-Warning -Exactly -Times 0 -Scope it
            }
        }

        Context 'RegistrationData' {
            It 'Should Copy registrations from ESE to SQL when they do not exist in SQL' {
                Mock -CommandName Get-DSCPullServerAdminRegistration -MockWith {
                    param (
                        $Connection
                    )
                    if ($Connection.Type -eq 'ESE') {
                        $registration
                    }
                }

                Mock -CommandName Invoke-DSCPullServerSQLCommand -MockWith {
                    param (
                        $Script
                    )
                    Write-Verbose -Message $Script -Verbose
                }

                Mock -CommandName Write-Warning

                $result = Copy-DSCPullServerAdminData -Connection1 $eseConnection -Connection2 $sqlConnection -ObjectsToMigrate RegistrationData 4>&1
                $result | Should -Not -BeNullOrEmpty
                ($result | Measure-Object).Count | Should -BeExactly 1

                Assert-MockCalled -CommandName Get-DSCPullServerAdminRegistration -Exactly -Times 2 -Scope it
                Assert-MockCalled -CommandName Invoke-DSCPullServerSQLCommand -Exactly -Times 1 -Scope it
                Assert-MockCalled -CommandName Write-Warning -Exactly -Times 0 -Scope it
            }

            It 'Should write a warning when copying registrations from ESE to SQL when they already exist in SQL' {
                Mock -CommandName Get-DSCPullServerAdminRegistration -MockWith {
                    $registration
                }

                Mock -CommandName Invoke-DSCPullServerSQLCommand -MockWith {
                    param (
                        $Script
                    )
                    Write-Verbose -Message $Script -Verbose
                }

                Mock -CommandName Write-Warning

                $result = Copy-DSCPullServerAdminData -Connection1 $eseConnection -Connection2 $sqlConnection -ObjectsToMigrate RegistrationData 4>&1
                $result | Should -BeNullOrEmpty
                ($result | Measure-Object).Count | Should -BeExactly 0

                Assert-MockCalled -CommandName Get-DSCPullServerAdminRegistration -Exactly -Times 2 -Scope it
                Assert-MockCalled -CommandName Invoke-DSCPullServerSQLCommand -Exactly -Times 0 -Scope it
                Assert-MockCalled -CommandName Write-Warning -Exactly -Times 1 -Scope it
            }

            It 'Should overwrite a registration when copying registrations from ESE to SQL when they already exist in SQL but force switch was used' {
                Mock -CommandName Get-DSCPullServerAdminRegistration -MockWith {
                    $registration
                }

                Mock -CommandName Invoke-DSCPullServerSQLCommand -MockWith {
                    param (
                        $Script
                    )
                    Write-Verbose -Message $Script -Verbose
                }

                Mock -CommandName Write-Warning

                $result = Copy-DSCPullServerAdminData -Connection1 $eseConnection -Connection2 $sqlConnection -ObjectsToMigrate RegistrationData -Force 4>&1
                $result | Should -Not -BeNullOrEmpty
                ($result | Measure-Object).Count | Should -BeExactly 2

                Assert-MockCalled -CommandName Get-DSCPullServerAdminRegistration -Exactly -Times 2 -Scope it
                Assert-MockCalled -CommandName Invoke-DSCPullServerSQLCommand -Exactly -Times 2 -Scope it
                Assert-MockCalled -CommandName Write-Warning -Exactly -Times 0 -Scope it
            }

            It 'Should have ShouldProcess before calling Invoke-DSCPullServerSQLCommand when registration does not exist in SQL' {
                Mock -CommandName Get-DSCPullServerAdminDevice -MockWith {
                    param (
                        $Connection
                    )
                    if ($Connection.Type -eq 'ESE') {
                        $registration
                    }
                }

                Mock -CommandName Invoke-DSCPullServerSQLCommand

                Mock -CommandName Write-Warning

                Copy-DSCPullServerAdminData -Connection1 $eseConnection -Connection2 $sqlConnection -ObjectsToMigrate RegistrationData -WhatIf

                Assert-MockCalled -CommandName Get-DSCPullServerAdminRegistration -Exactly -Times 2 -Scope it
                Assert-MockCalled -CommandName Invoke-DSCPullServerSQLCommand -Exactly -Times 0 -Scope it
                Assert-MockCalled -CommandName Write-Warning -Exactly -Times 0 -Scope it
            }

            It 'Should have ShouldProcess before calling Invoke-DSCPullServerSQLCommand when registration already exists in SQL' {
                Mock -CommandName Get-DSCPullServerAdminRegistration -MockWith {
                    $registration
                }

                Mock -CommandName Invoke-DSCPullServerSQLCommand

                Mock -CommandName Write-Warning

                Copy-DSCPullServerAdminData -Connection1 $eseConnection -Connection2 $sqlConnection -ObjectsToMigrate RegistrationData -WhatIf

                Assert-MockCalled -CommandName Get-DSCPullServerAdminRegistration -Exactly -Times 2 -Scope it
                Assert-MockCalled -CommandName Invoke-DSCPullServerSQLCommand -Exactly -Times 0 -Scope it
                Assert-MockCalled -CommandName Write-Warning -Exactly -Times 0 -Scope it
            }
        }

        Context 'StatusReports' {
            It 'Should Copy reports from ESE to SQL when they do not exist in SQL' {
                Mock -CommandName Get-DSCPullServerAdminStatusReport -MockWith {
                    param (
                        $Connection
                    )
                    if ($Connection.Type -eq 'ESE') {
                        $report
                    }
                }

                Mock -CommandName Invoke-DSCPullServerSQLCommand -MockWith {
                    param (
                        $Script
                    )
                    Write-Verbose -Message $Script -Verbose
                }

                Mock -CommandName Write-Warning

                $result = Copy-DSCPullServerAdminData -Connection1 $eseConnection -Connection2 $sqlConnection -ObjectsToMigrate StatusReports 4>&1
                $result | Should -Not -BeNullOrEmpty
                ($result | Measure-Object).Count | Should -BeExactly 1

                Assert-MockCalled -CommandName Get-DSCPullServerAdminStatusReport -Exactly -Times 2 -Scope it
                Assert-MockCalled -CommandName Invoke-DSCPullServerSQLCommand -Exactly -Times 1 -Scope it
                Assert-MockCalled -CommandName Write-Warning -Exactly -Times 0 -Scope it
            }

            It 'Should write a warning when copying reports from ESE to SQL when they already exist in SQL' {
                Mock -CommandName Get-DSCPullServerAdminStatusReport -MockWith {
                    $report
                }

                Mock -CommandName Invoke-DSCPullServerSQLCommand -MockWith {
                    param (
                        $Script
                    )
                    Write-Verbose -Message $Script -Verbose
                }

                Mock -CommandName Write-Warning

                $result = Copy-DSCPullServerAdminData -Connection1 $eseConnection -Connection2 $sqlConnection -ObjectsToMigrate StatusReports 4>&1
                $result | Should -BeNullOrEmpty
                ($result | Measure-Object).Count | Should -BeExactly 0

                Assert-MockCalled -CommandName Get-DSCPullServerAdminStatusReport -Exactly -Times 2 -Scope it
                Assert-MockCalled -CommandName Invoke-DSCPullServerSQLCommand -Exactly -Times 0 -Scope it
                Assert-MockCalled -CommandName Write-Warning -Exactly -Times 1 -Scope it
            }

            It 'Should overwrite a report when copying reports from ESE to SQL when they already exist in SQL but force switch was used' {
                Mock -CommandName Get-DSCPullServerAdminStatusReport -MockWith {
                    $report
                }

                Mock -CommandName Invoke-DSCPullServerSQLCommand -MockWith {
                    param (
                        $Script
                    )
                    Write-Verbose -Message $Script -Verbose
                }

                Mock -CommandName Write-Warning

                $result = Copy-DSCPullServerAdminData -Connection1 $eseConnection -Connection2 $sqlConnection -ObjectsToMigrate StatusReports -Force 4>&1
                $result | Should -Not -BeNullOrEmpty
                ($result | Measure-Object).Count | Should -BeExactly 2

                Assert-MockCalled -CommandName Get-DSCPullServerAdminStatusReport -Exactly -Times 2 -Scope it
                Assert-MockCalled -CommandName Invoke-DSCPullServerSQLCommand -Exactly -Times 2 -Scope it
                Assert-MockCalled -CommandName Write-Warning -Exactly -Times 0 -Scope it
            }

            It 'Should have ShouldProcess before calling Invoke-DSCPullServerSQLCommand when report does not exist in SQL' {
                Mock -CommandName Get-DSCPullServerAdminStatusReport -MockWith {
                    param (
                        $Connection
                    )
                    if ($Connection.Type -eq 'ESE') {
                        $report
                    }
                }

                Mock -CommandName Invoke-DSCPullServerSQLCommand

                Mock -CommandName Write-Warning

                Copy-DSCPullServerAdminData -Connection1 $eseConnection -Connection2 $sqlConnection -ObjectsToMigrate StatusReports -WhatIf

                Assert-MockCalled -CommandName Get-DSCPullServerAdminStatusReport -Exactly -Times 2 -Scope it
                Assert-MockCalled -CommandName Invoke-DSCPullServerSQLCommand -Exactly -Times 0 -Scope it
                Assert-MockCalled -CommandName Write-Warning -Exactly -Times 0 -Scope it
            }

            It 'Should have ShouldProcess before calling Invoke-DSCPullServerSQLCommand when report already exists in SQL' {
                Mock -CommandName Get-DSCPullServerAdminStatusReport -MockWith {
                    $report
                }

                Mock -CommandName Invoke-DSCPullServerSQLCommand

                Mock -CommandName Write-Warning

                Copy-DSCPullServerAdminData -Connection1 $eseConnection -Connection2 $sqlConnection -ObjectsToMigrate StatusReports -WhatIf

                Assert-MockCalled -CommandName Get-DSCPullServerAdminStatusReport -Exactly -Times 2 -Scope it
                Assert-MockCalled -CommandName Invoke-DSCPullServerSQLCommand -Exactly -Times 0 -Scope it
                Assert-MockCalled -CommandName Write-Warning -Exactly -Times 0 -Scope it
            }
        }
    }
}
