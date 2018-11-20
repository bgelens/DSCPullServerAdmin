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
    $registration.NodeName = 'bogusRegistration'
    $registration.LCMVersion = '2.0'

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

                Mock -CommandName New-DSCPullServerAdminDevice

                Mock -CommandName Set-DSCPullServerAdminDevice

                # with SQL we check for the TSQL Script to be generated
                $result = Copy-DSCPullServerAdminData -Connection1 $eseConnection -Connection2 $sqlConnection -ObjectsToMigrate Devices 4>&1
                $result | Should -Not -BeNullOrEmpty
                ($result | Measure-Object).Count | Should -BeExactly 1

                Assert-MockCalled -CommandName Get-DSCPullServerAdminDevice -Exactly -Times 2 -Scope it
                Assert-MockCalled -CommandName Invoke-DSCPullServerSQLCommand -Exactly -Times 1 -Scope it
                Assert-MockCalled -CommandName Write-Warning -Exactly -Times 0 -Scope it
                Assert-MockCalled -CommandName New-DSCPullServerAdminDevice -Exactly -Times 0 -Scope it
                Assert-MockCalled -CommandName Set-DSCPullServerAdminDevice -Exactly -Times 0 -Scope it
            }

            It 'Should Copy devices from SQL to ESE when they do not exist in ESE' {
                Mock -CommandName Get-DSCPullServerAdminDevice -MockWith {
                    param (
                        $Connection
                    )
                    if ($Connection.Type -eq 'SQL') {
                        $device
                    }
                }

                Mock -CommandName Invoke-DSCPullServerSQLCommand

                Mock -CommandName Write-Warning

                Mock -CommandName New-DSCPullServerAdminDevice

                Mock -CommandName Set-DSCPullServerAdminDevice

                # with ESE there is no script generated so the output should be null
                $result = Copy-DSCPullServerAdminData -Connection1 $sqlConnection -Connection2 $eseConnection -ObjectsToMigrate Devices 4>&1
                $result | Should -BeNullOrEmpty

                Assert-MockCalled -CommandName Get-DSCPullServerAdminDevice -Exactly -Times 2 -Scope it
                Assert-MockCalled -CommandName Invoke-DSCPullServerSQLCommand -Exactly -Times 0 -Scope it
                Assert-MockCalled -CommandName Write-Warning -Exactly -Times 0 -Scope it
                Assert-MockCalled -CommandName New-DSCPullServerAdminDevice -Exactly -Times 1 -Scope it
                Assert-MockCalled -CommandName Set-DSCPullServerAdminDevice -Exactly -Times 0 -Scope it
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

                Mock -CommandName New-DSCPullServerAdminDevice

                Mock -CommandName Set-DSCPullServerAdminDevice

                $result = Copy-DSCPullServerAdminData -Connection1 $eseConnection -Connection2 $sqlConnection -ObjectsToMigrate Devices 4>&1
                $result | Should -BeNullOrEmpty
                ($result | Measure-Object).Count | Should -BeExactly 0

                Assert-MockCalled -CommandName Get-DSCPullServerAdminDevice -Exactly -Times 2 -Scope it
                Assert-MockCalled -CommandName Invoke-DSCPullServerSQLCommand -Exactly -Times 0 -Scope it
                Assert-MockCalled -CommandName Write-Warning -Exactly -Times 1 -Scope it
                Assert-MockCalled -CommandName New-DSCPullServerAdminDevice -Exactly -Times 0 -Scope it
                Assert-MockCalled -CommandName Set-DSCPullServerAdminDevice -Exactly -Times 0 -Scope it
            }

            It 'Should write a warning when copying devices from SQL to ESE when they already exist in ESE' {
                Mock -CommandName Get-DSCPullServerAdminDevice -MockWith {
                    $device
                }

                Mock -CommandName Invoke-DSCPullServerSQLCommand

                Mock -CommandName Write-Warning

                Mock -CommandName New-DSCPullServerAdminDevice

                Mock -CommandName Set-DSCPullServerAdminDevice

                $result = Copy-DSCPullServerAdminData -Connection1 $sqlConnection -Connection2 $eseConnection -ObjectsToMigrate Devices 4>&1
                $result | Should -BeNullOrEmpty

                Assert-MockCalled -CommandName Get-DSCPullServerAdminDevice -Exactly -Times 2 -Scope it
                Assert-MockCalled -CommandName Invoke-DSCPullServerSQLCommand -Exactly -Times 0 -Scope it
                Assert-MockCalled -CommandName Write-Warning -Exactly -Times 1 -Scope it
                Assert-MockCalled -CommandName New-DSCPullServerAdminDevice -Exactly -Times 0 -Scope it
                Assert-MockCalled -CommandName Set-DSCPullServerAdminDevice -Exactly -Times 0 -Scope it
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

                Mock -CommandName New-DSCPullServerAdminDevice

                Mock -CommandName Set-DSCPullServerAdminDevice

                $result = Copy-DSCPullServerAdminData -Connection1 $eseConnection -Connection2 $sqlConnection -ObjectsToMigrate Devices -Force 4>&1
                $result | Should -Not -BeNullOrEmpty
                ($result | Measure-Object).Count | Should -BeExactly 2

                Assert-MockCalled -CommandName Get-DSCPullServerAdminDevice -Exactly -Times 2 -Scope it
                Assert-MockCalled -CommandName Invoke-DSCPullServerSQLCommand -Exactly -Times 2 -Scope it
                Assert-MockCalled -CommandName Write-Warning -Exactly -Times 0 -Scope it
                Assert-MockCalled -CommandName New-DSCPullServerAdminDevice -Exactly -Times 0 -Scope it
                Assert-MockCalled -CommandName Set-DSCPullServerAdminDevice -Exactly -Times 0 -Scope it
            }

            It 'Should overwrite a device when copying devices from SQL to ESE when they already exist in ESE but force switch was used' {
                Mock -CommandName Get-DSCPullServerAdminDevice -MockWith {
                    $device
                }

                Mock -CommandName Invoke-DSCPullServerSQLCommand

                Mock -CommandName Write-Warning

                Mock -CommandName New-DSCPullServerAdminDevice

                Mock -CommandName Set-DSCPullServerAdminDevice

                $result = Copy-DSCPullServerAdminData -Connection1 $sqlConnection -Connection2 $eseConnection -ObjectsToMigrate Devices -Force 4>&1
                $result | Should -BeNullOrEmpty

                Assert-MockCalled -CommandName Get-DSCPullServerAdminDevice -Exactly -Times 2 -Scope it
                Assert-MockCalled -CommandName Invoke-DSCPullServerSQLCommand -Exactly -Times 0 -Scope it
                Assert-MockCalled -CommandName Write-Warning -Exactly -Times 0 -Scope it
                Assert-MockCalled -CommandName New-DSCPullServerAdminDevice -Exactly -Times 0 -Scope it
                Assert-MockCalled -CommandName Set-DSCPullServerAdminDevice -Exactly -Times 1 -Scope it
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

                Mock -CommandName New-DSCPullServerAdminDevice

                Mock -CommandName Set-DSCPullServerAdminDevice

                Copy-DSCPullServerAdminData -Connection1 $eseConnection -Connection2 $sqlConnection -ObjectsToMigrate Devices -WhatIf

                Assert-MockCalled -CommandName Get-DSCPullServerAdminDevice -Exactly -Times 2 -Scope it
                Assert-MockCalled -CommandName Invoke-DSCPullServerSQLCommand -Exactly -Times 0 -Scope it
                Assert-MockCalled -CommandName Write-Warning -Exactly -Times 0 -Scope it
                Assert-MockCalled -CommandName New-DSCPullServerAdminDevice -Exactly -Times 0 -Scope it
                Assert-MockCalled -CommandName Set-DSCPullServerAdminDevice -Exactly -Times 0 -Scope it
            }

            It 'Should have ShouldProcess before calling New-DSCPullServerAdminDevice when device does not exist in ESE' {
                Mock -CommandName Get-DSCPullServerAdminDevice -MockWith {
                    param (
                        $Connection
                    )
                    if ($Connection.Type -eq 'SQL') {
                        $device
                    }
                }

                Mock -CommandName Invoke-DSCPullServerSQLCommand

                Mock -CommandName Write-Warning

                Mock -CommandName New-DSCPullServerAdminDevice

                Mock -CommandName Set-DSCPullServerAdminDevice

                Copy-DSCPullServerAdminData -Connection1 $sqlConnection -Connection2 $eseConnection -ObjectsToMigrate Devices -WhatIf

                Assert-MockCalled -CommandName Get-DSCPullServerAdminDevice -Exactly -Times 2 -Scope it
                Assert-MockCalled -CommandName Invoke-DSCPullServerSQLCommand -Exactly -Times 0 -Scope it
                Assert-MockCalled -CommandName Write-Warning -Exactly -Times 0 -Scope it
                Assert-MockCalled -CommandName New-DSCPullServerAdminDevice -Exactly -Times 0 -Scope it
                Assert-MockCalled -CommandName Set-DSCPullServerAdminDevice -Exactly -Times 0 -Scope it
            }

            It 'Should have ShouldProcess before calling Invoke-DSCPullServerSQLCommand when device already exists in SQL' {
                Mock -CommandName Get-DSCPullServerAdminDevice -MockWith {
                    $device
                }

                Mock -CommandName Invoke-DSCPullServerSQLCommand

                Mock -CommandName Write-Warning

                Mock -CommandName New-DSCPullServerAdminDevice

                Mock -CommandName Set-DSCPullServerAdminDevice

                Copy-DSCPullServerAdminData -Connection1 $eseConnection -Connection2 $sqlConnection -ObjectsToMigrate Devices -WhatIf

                Assert-MockCalled -CommandName Get-DSCPullServerAdminDevice -Exactly -Times 2 -Scope it
                Assert-MockCalled -CommandName Invoke-DSCPullServerSQLCommand -Exactly -Times 0 -Scope it
                Assert-MockCalled -CommandName Write-Warning -Exactly -Times 0 -Scope it
                Assert-MockCalled -CommandName New-DSCPullServerAdminDevice -Exactly -Times 0 -Scope it
                Assert-MockCalled -CommandName Set-DSCPullServerAdminDevice -Exactly -Times 0 -Scope it
            }

            It 'Should have ShouldProcess before calling Set-DSCPullServerAdminDevice when device already exists in ESE' {
                Mock -CommandName Get-DSCPullServerAdminDevice -MockWith {
                    $device
                }

                Mock -CommandName Invoke-DSCPullServerSQLCommand

                Mock -CommandName Write-Warning

                Mock -CommandName New-DSCPullServerAdminDevice

                Mock -CommandName Set-DSCPullServerAdminDevice

                Copy-DSCPullServerAdminData -Connection1 $sqlConnection -Connection2 $eseConnection -ObjectsToMigrate Devices -WhatIf

                Assert-MockCalled -CommandName Get-DSCPullServerAdminDevice -Exactly -Times 2 -Scope it
                Assert-MockCalled -CommandName Invoke-DSCPullServerSQLCommand -Exactly -Times 0 -Scope it
                Assert-MockCalled -CommandName Write-Warning -Exactly -Times 0 -Scope it
                Assert-MockCalled -CommandName New-DSCPullServerAdminDevice -Exactly -Times 0 -Scope it
                Assert-MockCalled -CommandName Set-DSCPullServerAdminDevice -Exactly -Times 0 -Scope it
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

                Mock -CommandName New-DSCPullServerAdminRegistration

                Mock -CommandName Set-DSCPullServerAdminRegistration

                $result = Copy-DSCPullServerAdminData -Connection1 $eseConnection -Connection2 $sqlConnection -ObjectsToMigrate RegistrationData 4>&1
                $result | Should -Not -BeNullOrEmpty
                ($result | Measure-Object).Count | Should -BeExactly 1

                Assert-MockCalled -CommandName Get-DSCPullServerAdminRegistration -Exactly -Times 2 -Scope it
                Assert-MockCalled -CommandName Invoke-DSCPullServerSQLCommand -Exactly -Times 1 -Scope it
                Assert-MockCalled -CommandName Write-Warning -Exactly -Times 0 -Scope it
                Assert-MockCalled -CommandName New-DSCPullServerAdminRegistration -Exactly -Times 0 -Scope it
                Assert-MockCalled -CommandName Set-DSCPullServerAdminRegistration -Exactly -Times 0 -Scope it
            }

            It 'Should Copy registrations from SQL to ESE when they do not exist in ESE' {
                Mock -CommandName Get-DSCPullServerAdminRegistration -MockWith {
                    param (
                        $Connection
                    )
                    if ($Connection.Type -eq 'SQL') {
                        $registration
                    }
                }

                Mock -CommandName Invoke-DSCPullServerSQLCommand

                Mock -CommandName Write-Warning

                Mock -CommandName New-DSCPullServerAdminRegistration

                Mock -CommandName Set-DSCPullServerAdminRegistration

                $result = Copy-DSCPullServerAdminData -Connection1 $sqlConnection -Connection2 $eseConnection -ObjectsToMigrate RegistrationData 4>&1
                $result | Should -BeNullOrEmpty

                Assert-MockCalled -CommandName Get-DSCPullServerAdminRegistration -Exactly -Times 2 -Scope it
                Assert-MockCalled -CommandName Invoke-DSCPullServerSQLCommand -Exactly -Times 0 -Scope it
                Assert-MockCalled -CommandName Write-Warning -Exactly -Times 0 -Scope it
                Assert-MockCalled -CommandName New-DSCPullServerAdminRegistration -Exactly -Times 1 -Scope it
                Assert-MockCalled -CommandName Set-DSCPullServerAdminRegistration -Exactly -Times 0 -Scope it
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

                Mock -CommandName New-DSCPullServerAdminRegistration

                Mock -CommandName Set-DSCPullServerAdminRegistration

                $result = Copy-DSCPullServerAdminData -Connection1 $eseConnection -Connection2 $sqlConnection -ObjectsToMigrate RegistrationData 4>&1
                $result | Should -BeNullOrEmpty
                ($result | Measure-Object).Count | Should -BeExactly 0

                Assert-MockCalled -CommandName Get-DSCPullServerAdminRegistration -Exactly -Times 2 -Scope it
                Assert-MockCalled -CommandName Invoke-DSCPullServerSQLCommand -Exactly -Times 0 -Scope it
                Assert-MockCalled -CommandName Write-Warning -Exactly -Times 1 -Scope it
                Assert-MockCalled -CommandName New-DSCPullServerAdminRegistration -Exactly -Times 0 -Scope it
                Assert-MockCalled -CommandName Set-DSCPullServerAdminRegistration -Exactly -Times 0 -Scope it
            }

            It 'Should write a warning when copying registrations from SQL to ESE when they already exist in ESE' {
                Mock -CommandName Get-DSCPullServerAdminRegistration -MockWith {
                    $registration
                }

                Mock -CommandName Invoke-DSCPullServerSQLCommand

                Mock -CommandName Write-Warning

                Mock -CommandName New-DSCPullServerAdminRegistration

                Mock -CommandName Set-DSCPullServerAdminRegistration

                $result = Copy-DSCPullServerAdminData -Connection1 $sqlConnection -Connection2 $eseConnection -ObjectsToMigrate RegistrationData 4>&1
                $result | Should -BeNullOrEmpty

                Assert-MockCalled -CommandName Get-DSCPullServerAdminRegistration -Exactly -Times 2 -Scope it
                Assert-MockCalled -CommandName Invoke-DSCPullServerSQLCommand -Exactly -Times 0 -Scope it
                Assert-MockCalled -CommandName Write-Warning -Exactly -Times 1 -Scope it
                Assert-MockCalled -CommandName New-DSCPullServerAdminRegistration -Exactly -Times 0 -Scope it
                Assert-MockCalled -CommandName Set-DSCPullServerAdminRegistration -Exactly -Times 0 -Scope it
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

                Mock -CommandName New-DSCPullServerAdminRegistration

                Mock -CommandName Set-DSCPullServerAdminRegistration

                $result = Copy-DSCPullServerAdminData -Connection1 $eseConnection -Connection2 $sqlConnection -ObjectsToMigrate RegistrationData -Force 4>&1
                $result | Should -Not -BeNullOrEmpty
                ($result | Measure-Object).Count | Should -BeExactly 2

                Assert-MockCalled -CommandName Get-DSCPullServerAdminRegistration -Exactly -Times 2 -Scope it
                Assert-MockCalled -CommandName Invoke-DSCPullServerSQLCommand -Exactly -Times 2 -Scope it
                Assert-MockCalled -CommandName Write-Warning -Exactly -Times 0 -Scope it
                Assert-MockCalled -CommandName New-DSCPullServerAdminRegistration -Exactly -Times 0 -Scope it
                Assert-MockCalled -CommandName Set-DSCPullServerAdminRegistration -Exactly -Times 0 -Scope it
            }

            It 'Should overwrite a registration when copying registrations from SQL to ESE when they already exist in ESE but force switch was used' {
                Mock -CommandName Get-DSCPullServerAdminRegistration -MockWith {
                    $registration
                }

                Mock -CommandName Invoke-DSCPullServerSQLCommand

                Mock -CommandName Write-Warning

                Mock -CommandName New-DSCPullServerAdminRegistration

                Mock -CommandName Set-DSCPullServerAdminRegistration

                $result = Copy-DSCPullServerAdminData -Connection1 $sqlConnection -Connection2 $eseConnection -ObjectsToMigrate RegistrationData -Force 4>&1
                $result | Should -BeNullOrEmpty

                Assert-MockCalled -CommandName Get-DSCPullServerAdminRegistration -Exactly -Times 2 -Scope it
                Assert-MockCalled -CommandName Invoke-DSCPullServerSQLCommand -Exactly -Times 0 -Scope it
                Assert-MockCalled -CommandName Write-Warning -Exactly -Times 0 -Scope it
                Assert-MockCalled -CommandName New-DSCPullServerAdminRegistration -Exactly -Times 0 -Scope it
                Assert-MockCalled -CommandName Set-DSCPullServerAdminRegistration -Exactly -Times 1 -Scope it
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

                Mock -CommandName New-DSCPullServerAdminRegistration

                Mock -CommandName Set-DSCPullServerAdminRegistration

                Copy-DSCPullServerAdminData -Connection1 $eseConnection -Connection2 $sqlConnection -ObjectsToMigrate RegistrationData -WhatIf

                Assert-MockCalled -CommandName Get-DSCPullServerAdminRegistration -Exactly -Times 2 -Scope it
                Assert-MockCalled -CommandName Invoke-DSCPullServerSQLCommand -Exactly -Times 0 -Scope it
                Assert-MockCalled -CommandName Write-Warning -Exactly -Times 0 -Scope it
                Assert-MockCalled -CommandName New-DSCPullServerAdminRegistration -Exactly -Times 0 -Scope it
                Assert-MockCalled -CommandName Set-DSCPullServerAdminRegistration -Exactly -Times 0 -Scope it
            }

            It 'Should have ShouldProcess before calling New-DSCPullServerAdminRegistration when registration does not exist in ESE' {
                Mock -CommandName Get-DSCPullServerAdminDevice -MockWith {
                    param (
                        $Connection
                    )
                    if ($Connection.Type -eq 'SQL') {
                        $registration
                    }
                }

                Mock -CommandName Invoke-DSCPullServerSQLCommand

                Mock -CommandName Write-Warning

                Mock -CommandName New-DSCPullServerAdminRegistration

                Mock -CommandName Set-DSCPullServerAdminRegistration

                Copy-DSCPullServerAdminData -Connection1 $sqlConnection -Connection2 $eseConnection -ObjectsToMigrate RegistrationData -WhatIf

                Assert-MockCalled -CommandName Get-DSCPullServerAdminRegistration -Exactly -Times 2 -Scope it
                Assert-MockCalled -CommandName Invoke-DSCPullServerSQLCommand -Exactly -Times 0 -Scope it
                Assert-MockCalled -CommandName Write-Warning -Exactly -Times 0 -Scope it
                Assert-MockCalled -CommandName New-DSCPullServerAdminRegistration -Exactly -Times 0 -Scope it
                Assert-MockCalled -CommandName Set-DSCPullServerAdminRegistration -Exactly -Times 0 -Scope it
            }

            It 'Should have ShouldProcess before calling Invoke-DSCPullServerSQLCommand when registration already exists in SQL' {
                Mock -CommandName Get-DSCPullServerAdminRegistration -MockWith {
                    $registration
                }

                Mock -CommandName Invoke-DSCPullServerSQLCommand

                Mock -CommandName Write-Warning

                Mock -CommandName New-DSCPullServerAdminRegistration

                Mock -CommandName Set-DSCPullServerAdminRegistration

                Copy-DSCPullServerAdminData -Connection1 $eseConnection -Connection2 $sqlConnection -ObjectsToMigrate RegistrationData -WhatIf

                Assert-MockCalled -CommandName Get-DSCPullServerAdminRegistration -Exactly -Times 2 -Scope it
                Assert-MockCalled -CommandName Invoke-DSCPullServerSQLCommand -Exactly -Times 0 -Scope it
                Assert-MockCalled -CommandName Write-Warning -Exactly -Times 0 -Scope it
                Assert-MockCalled -CommandName New-DSCPullServerAdminRegistration -Exactly -Times 0 -Scope it
                Assert-MockCalled -CommandName Set-DSCPullServerAdminRegistration -Exactly -Times 0 -Scope it
            }

            It 'Should have ShouldProcess before calling Set-DSCPullServerAdminRegistration when registration already exists in ESE' {
                Mock -CommandName Get-DSCPullServerAdminRegistration -MockWith {
                    $registration
                }

                Mock -CommandName Invoke-DSCPullServerSQLCommand

                Mock -CommandName Write-Warning

                Mock -CommandName New-DSCPullServerAdminRegistration

                Mock -CommandName Set-DSCPullServerAdminRegistration

                Copy-DSCPullServerAdminData -Connection1 $sqlConnection -Connection2 $eseConnection -ObjectsToMigrate RegistrationData -WhatIf

                Assert-MockCalled -CommandName Get-DSCPullServerAdminRegistration -Exactly -Times 2 -Scope it
                Assert-MockCalled -CommandName Invoke-DSCPullServerSQLCommand -Exactly -Times 0 -Scope it
                Assert-MockCalled -CommandName Write-Warning -Exactly -Times 0 -Scope it
                Assert-MockCalled -CommandName New-DSCPullServerAdminRegistration -Exactly -Times 0 -Scope it
                Assert-MockCalled -CommandName Set-DSCPullServerAdminRegistration -Exactly -Times 0 -Scope it
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

                Mock -CommandName New-DSCPullServerAdminStatusReport

                Mock -CommandName Set-DSCPullServerAdminStatusReport

                $result = Copy-DSCPullServerAdminData -Connection1 $eseConnection -Connection2 $sqlConnection -ObjectsToMigrate StatusReports 4>&1
                $result | Should -Not -BeNullOrEmpty
                ($result | Measure-Object).Count | Should -BeExactly 1

                Assert-MockCalled -CommandName Get-DSCPullServerAdminStatusReport -Exactly -Times 2 -Scope it
                Assert-MockCalled -CommandName Invoke-DSCPullServerSQLCommand -Exactly -Times 1 -Scope it
                Assert-MockCalled -CommandName Write-Warning -Exactly -Times 0 -Scope it
                Assert-MockCalled -CommandName New-DSCPullServerAdminStatusReport -Exactly -Times 0 -Scope it
                Assert-MockCalled -CommandName Set-DSCPullServerAdminStatusReport -Exactly -Times 0 -Scope it
            }

            It 'Should Copy reports from SQL to ESE when they do not exist in ESE' {
                Mock -CommandName Get-DSCPullServerAdminStatusReport -MockWith {
                    param (
                        $Connection
                    )
                    if ($Connection.Type -eq 'SQL') {
                        $report
                    }
                }

                Mock -CommandName Invoke-DSCPullServerSQLCommand

                Mock -CommandName Write-Warning

                Mock -CommandName New-DSCPullServerAdminStatusReport

                Mock -CommandName Set-DSCPullServerAdminStatusReport

                $result = Copy-DSCPullServerAdminData -Connection1 $sqlConnection -Connection2 $eseConnection -ObjectsToMigrate StatusReports 4>&1
                $result | Should -BeNullOrEmpty

                Assert-MockCalled -CommandName Get-DSCPullServerAdminStatusReport -Exactly -Times 2 -Scope it
                Assert-MockCalled -CommandName Invoke-DSCPullServerSQLCommand -Exactly -Times 0 -Scope it
                Assert-MockCalled -CommandName Write-Warning -Exactly -Times 0 -Scope it
                Assert-MockCalled -CommandName New-DSCPullServerAdminStatusReport -Exactly -Times 1 -Scope it
                Assert-MockCalled -CommandName Set-DSCPullServerAdminStatusReport -Exactly -Times 0 -Scope it
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

                Mock -CommandName New-DSCPullServerAdminStatusReport

                Mock -CommandName Set-DSCPullServerAdminStatusReport

                $result = Copy-DSCPullServerAdminData -Connection1 $eseConnection -Connection2 $sqlConnection -ObjectsToMigrate StatusReports 4>&1
                $result | Should -BeNullOrEmpty
                ($result | Measure-Object).Count | Should -BeExactly 0

                Assert-MockCalled -CommandName Get-DSCPullServerAdminStatusReport -Exactly -Times 2 -Scope it
                Assert-MockCalled -CommandName Invoke-DSCPullServerSQLCommand -Exactly -Times 0 -Scope it
                Assert-MockCalled -CommandName Write-Warning -Exactly -Times 1 -Scope it
                Assert-MockCalled -CommandName New-DSCPullServerAdminStatusReport -Exactly -Times 0 -Scope it
                Assert-MockCalled -CommandName Set-DSCPullServerAdminStatusReport -Exactly -Times 0 -Scope it
            }

            It 'Should write a warning when copying reports from SQL to ESE when they already exist in ESE' {
                Mock -CommandName Get-DSCPullServerAdminStatusReport -MockWith {
                    $report
                }

                Mock -CommandName Invoke-DSCPullServerSQLCommand

                Mock -CommandName Write-Warning

                Mock -CommandName New-DSCPullServerAdminStatusReport

                Mock -CommandName Set-DSCPullServerAdminStatusReport

                $result = Copy-DSCPullServerAdminData -Connection1 $sqlConnection -Connection2 $eseConnection -ObjectsToMigrate StatusReports 4>&1
                $result | Should -BeNullOrEmpty

                Assert-MockCalled -CommandName Get-DSCPullServerAdminStatusReport -Exactly -Times 2 -Scope it
                Assert-MockCalled -CommandName Invoke-DSCPullServerSQLCommand -Exactly -Times 0 -Scope it
                Assert-MockCalled -CommandName Write-Warning -Exactly -Times 1 -Scope it
                Assert-MockCalled -CommandName New-DSCPullServerAdminStatusReport -Exactly -Times 0 -Scope it
                Assert-MockCalled -CommandName Set-DSCPullServerAdminStatusReport -Exactly -Times 0 -Scope it
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

                Mock -CommandName New-DSCPullServerAdminStatusReport

                Mock -CommandName Set-DSCPullServerAdminStatusReport

                $result = Copy-DSCPullServerAdminData -Connection1 $eseConnection -Connection2 $sqlConnection -ObjectsToMigrate StatusReports -Force 4>&1
                $result | Should -Not -BeNullOrEmpty
                ($result | Measure-Object).Count | Should -BeExactly 2

                Assert-MockCalled -CommandName Get-DSCPullServerAdminStatusReport -Exactly -Times 2 -Scope it
                Assert-MockCalled -CommandName Invoke-DSCPullServerSQLCommand -Exactly -Times 2 -Scope it
                Assert-MockCalled -CommandName Write-Warning -Exactly -Times 0 -Scope it
                Assert-MockCalled -CommandName New-DSCPullServerAdminStatusReport -Exactly -Times 0 -Scope it
                Assert-MockCalled -CommandName Set-DSCPullServerAdminStatusReport -Exactly -Times 0 -Scope it
            }

            It 'Should overwrite a report when copying reports from SQL to ESE when they already exist in ESE but force switch was used' {
                Mock -CommandName Get-DSCPullServerAdminStatusReport -MockWith {
                    $report
                }

                Mock -CommandName Invoke-DSCPullServerSQLCommand

                Mock -CommandName Write-Warning

                Mock -CommandName New-DSCPullServerAdminStatusReport

                Mock -CommandName Set-DSCPullServerAdminStatusReport

                $result = Copy-DSCPullServerAdminData -Connection1 $sqlConnection -Connection2 $eseConnection -ObjectsToMigrate StatusReports -Force 4>&1
                $result | Should -BeNullOrEmpty

                Assert-MockCalled -CommandName Get-DSCPullServerAdminStatusReport -Exactly -Times 2 -Scope it
                Assert-MockCalled -CommandName Invoke-DSCPullServerSQLCommand -Exactly -Times 0 -Scope it
                Assert-MockCalled -CommandName Write-Warning -Exactly -Times 0 -Scope it
                Assert-MockCalled -CommandName New-DSCPullServerAdminStatusReport -Exactly -Times 0 -Scope it
                Assert-MockCalled -CommandName Set-DSCPullServerAdminStatusReport -Exactly -Times 1 -Scope it
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

                Mock -CommandName New-DSCPullServerAdminStatusReport

                Mock -CommandName Set-DSCPullServerAdminStatusReport

                Copy-DSCPullServerAdminData -Connection1 $eseConnection -Connection2 $sqlConnection -ObjectsToMigrate StatusReports -WhatIf

                Assert-MockCalled -CommandName Get-DSCPullServerAdminStatusReport -Exactly -Times 2 -Scope it
                Assert-MockCalled -CommandName Invoke-DSCPullServerSQLCommand -Exactly -Times 0 -Scope it
                Assert-MockCalled -CommandName Write-Warning -Exactly -Times 0 -Scope it
                Assert-MockCalled -CommandName New-DSCPullServerAdminStatusReport -Exactly -Times 0 -Scope it
                Assert-MockCalled -CommandName Set-DSCPullServerAdminStatusReport -Exactly -Times 0 -Scope it
            }

            It 'Should have ShouldProcess before calling New-DSCPullServerAdminStatusReport when report does not exist in ESE' {
                Mock -CommandName Get-DSCPullServerAdminStatusReport -MockWith {
                    param (
                        $Connection
                    )
                    if ($Connection.Type -eq 'SQL') {
                        $report
                    }
                }

                Mock -CommandName Invoke-DSCPullServerSQLCommand

                Mock -CommandName Write-Warning

                Mock -CommandName New-DSCPullServerAdminStatusReport

                Mock -CommandName Set-DSCPullServerAdminStatusReport

                Copy-DSCPullServerAdminData -Connection1 $sqlConnection -Connection2 $eseConnection -ObjectsToMigrate StatusReports -WhatIf

                Assert-MockCalled -CommandName Get-DSCPullServerAdminStatusReport -Exactly -Times 2 -Scope it
                Assert-MockCalled -CommandName Invoke-DSCPullServerSQLCommand -Exactly -Times 0 -Scope it
                Assert-MockCalled -CommandName Write-Warning -Exactly -Times 0 -Scope it
                Assert-MockCalled -CommandName New-DSCPullServerAdminStatusReport -Exactly -Times 0 -Scope it
                Assert-MockCalled -CommandName Set-DSCPullServerAdminStatusReport -Exactly -Times 0 -Scope it
            }

            It 'Should have ShouldProcess before calling Invoke-DSCPullServerSQLCommand when report already exists in SQL' {
                Mock -CommandName Get-DSCPullServerAdminStatusReport -MockWith {
                    $report
                }

                Mock -CommandName Invoke-DSCPullServerSQLCommand

                Mock -CommandName Write-Warning

                Mock -CommandName New-DSCPullServerAdminStatusReport

                Mock -CommandName Set-DSCPullServerAdminStatusReport

                Copy-DSCPullServerAdminData -Connection1 $eseConnection -Connection2 $sqlConnection -ObjectsToMigrate StatusReports -WhatIf

                Assert-MockCalled -CommandName Get-DSCPullServerAdminStatusReport -Exactly -Times 2 -Scope it
                Assert-MockCalled -CommandName Invoke-DSCPullServerSQLCommand -Exactly -Times 0 -Scope it
                Assert-MockCalled -CommandName Write-Warning -Exactly -Times 0 -Scope it
                Assert-MockCalled -CommandName New-DSCPullServerAdminStatusReport -Exactly -Times 0 -Scope it
                Assert-MockCalled -CommandName Set-DSCPullServerAdminStatusReport -Exactly -Times 0 -Scope it
            }

            It 'Should have ShouldProcess before calling Set-DSCPullServerAdminStatusReport when report already exists in ESE' {
                Mock -CommandName Get-DSCPullServerAdminStatusReport -MockWith {
                    $report
                }

                Mock -CommandName Invoke-DSCPullServerSQLCommand

                Mock -CommandName Write-Warning

                Mock -CommandName New-DSCPullServerAdminStatusReport

                Mock -CommandName Set-DSCPullServerAdminStatusReport

                Copy-DSCPullServerAdminData -Connection1 $sqlConnection -Connection2 $eseConnection -ObjectsToMigrate StatusReports -WhatIf

                Assert-MockCalled -CommandName Get-DSCPullServerAdminStatusReport -Exactly -Times 2 -Scope it
                Assert-MockCalled -CommandName Invoke-DSCPullServerSQLCommand -Exactly -Times 0 -Scope it
                Assert-MockCalled -CommandName Write-Warning -Exactly -Times 0 -Scope it
                Assert-MockCalled -CommandName New-DSCPullServerAdminStatusReport -Exactly -Times 0 -Scope it
                Assert-MockCalled -CommandName Set-DSCPullServerAdminStatusReport -Exactly -Times 0 -Scope it
            }
        }
    }
}
