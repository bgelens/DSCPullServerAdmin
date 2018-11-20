$here = $PSScriptRoot

$modulePath = "$here\..\..\.."
$moduleName = Split-Path -Path $modulePath -Leaf

InModuleScope $moduleName {
    $sqlConnection = [DSCPullServerSQLConnection]::new()
    $sqlConnection.Active = $true
    $sqlConnection.Index = 0

    $eseConnection = [DSCPullServerESEConnection]::new()
    $eseConnection.Index = 1

    $registration = [DSCNodeRegistration]::new()
    $registration.AgentId = [guid]::Empty

    function GetRegistrationFromEDB {
        $script:GetConnection = $eseConnection
        $registration
    }

    Describe Remove-DSCPullServerAdminRegistration {
        Mock -CommandName PreProc -MockWith {
            $sqlConnection
        }

        It 'Should remove a registration when it is passed in via InputObject (pipeline) SQL' {
            Mock -CommandName Get-DSCPullServerAdminRegistration

            Mock -CommandName Invoke-DSCPullServerSQLCommand -MockWith {
                param (
                    $script
                )
                Write-Verbose -Message $Script -Verbose
            }

            Mock -CommandName Remove-DSCPullServerESERecord

            Mock -CommandName PreProc -MockWith {
                $sqlConnection
            }

            $result = $registration | Remove-DSCPullServerAdminRegistration -Confirm:$false 4>&1
            $result | Should -Not -BeNullOrEmpty

            Assert-MockCalled -CommandName Get-DSCPullServerAdminRegistration -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerSQLCommand -Exactly -Times 1 -Scope it
            Assert-MockCalled -CommandName Remove-DSCPullServerESERecord -Exactly -Times 0 -Scope it
        }

        It 'Should remove a registration when it is passed in via InputObject (pipeline) ESE' {
            Mock -CommandName Get-DSCPullServerAdminRegistration

            Mock -CommandName Invoke-DSCPullServerSQLCommand

            Mock -CommandName Remove-DSCPullServerESERecord

            Mock -CommandName PreProc -MockWith {
                $eseConnection
            }

            GetRegistrationFromEDB | Remove-DSCPullServerAdminRegistration -Confirm:$false 4>&1

            Assert-MockCalled -CommandName Get-DSCPullServerAdminRegistration -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerSQLCommand -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Remove-DSCPullServerESERecord -Exactly -Times 1 -Scope it
        }

        It 'Should remove a registration when AgentId was specified and registration was found (SQL)' {
            Mock -CommandName Get-DSCPullServerAdminRegistration -MockWith {
                $registration
            }

            Mock -CommandName Invoke-DSCPullServerSQLCommand -MockWith {
                param (
                    $script
                )
                Write-Verbose -Message $Script -Verbose
            }

            Mock -CommandName Remove-DSCPullServerESERecord

            Mock -CommandName PreProc -MockWith {
                $sqlConnection
            }

            $result = Remove-DSCPullServerAdminRegistration -AgentId ([guid]::Empty) -Connection $sqlConnection -Confirm:$false 4>&1
            $result | Should -Not -BeNullOrEmpty

            Assert-MockCalled -CommandName Get-DSCPullServerAdminRegistration -Exactly -Times 1 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerSQLCommand -Exactly -Times 1 -Scope it
            Assert-MockCalled -CommandName Remove-DSCPullServerESERecord -Exactly -Times 0 -Scope it
        }

        It 'Should remove a registration when AgentId was specified and registration was found (ESE)' {
            Mock -CommandName Get-DSCPullServerAdminRegistration -MockWith {
                $registration
            }

            Mock -CommandName Invoke-DSCPullServerSQLCommand

            Mock -CommandName Remove-DSCPullServerESERecord

            Mock -CommandName PreProc -MockWith {
                $eseConnection
            }

            Remove-DSCPullServerAdminRegistration -AgentId ([guid]::Empty) -Connection $eseConnection -Confirm:$false 4>&1

            Assert-MockCalled -CommandName Get-DSCPullServerAdminRegistration -Exactly -Times 2 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerSQLCommand -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Remove-DSCPullServerESERecord -Exactly -Times 1 -Scope it
        }

        It 'Should write a warning when AgentId was specified but registration was not found (SQL)' {
            Mock -CommandName Get-DSCPullServerAdminRegistration

            Mock -CommandName Invoke-DSCPullServerSQLCommand

            Mock -CommandName Write-Warning

            Mock -CommandName Remove-DSCPullServerESERecord

            Mock -CommandName PreProc -MockWith {
                $sqlConnection
            }

            Remove-DSCPullServerAdminRegistration -AgentId ([guid]::Empty)

            Assert-MockCalled -CommandName Get-DSCPullServerAdminRegistration -Exactly -Times 1 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerSQLCommand -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Write-Warning -Exactly -Times 1 -Scope it
            Assert-MockCalled -CommandName Remove-DSCPullServerESERecord -Exactly -Times 0 -Scope it
        }

        It 'Should write a warning when AgentId was specified but registration was not found (ESE)' {
            Mock -CommandName Get-DSCPullServerAdminRegistration

            Mock -CommandName Invoke-DSCPullServerSQLCommand

            Mock -CommandName Write-Warning

            Mock -CommandName Remove-DSCPullServerESERecord

            Mock -CommandName PreProc -MockWith {
                $eseConnection
            }

            Remove-DSCPullServerAdminRegistration -AgentId ([guid]::Empty)

            Assert-MockCalled -CommandName Get-DSCPullServerAdminRegistration -Exactly -Times 1 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerSQLCommand -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Write-Warning -Exactly -Times 1 -Scope it
            Assert-MockCalled -CommandName Remove-DSCPullServerESERecord -Exactly -Times 0 -Scope it
        }

        It 'Should have ShouldProcess before calling Invoke-DSCPullServerSQLCommand' {
            Mock -CommandName Get-DSCPullServerAdminRegistration

            Mock -CommandName Invoke-DSCPullServerSQLCommand

            Mock -CommandName Remove-DSCPullServerESERecord

            Mock -CommandName PreProc -MockWith {
                $sqlConnection
            }

            $registration | Remove-DSCPullServerAdminRegistration -WhatIf

            Assert-MockCalled -CommandName Get-DSCPullServerAdminRegistration -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerSQLCommand -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Remove-DSCPullServerESERecord -Exactly -Times 0 -Scope it
        }

        It 'Should have ShouldProcess before calling Remove-DSCPullServerESERecord' {
            Mock -CommandName Get-DSCPullServerAdminRegistration

            Mock -CommandName Invoke-DSCPullServerSQLCommand

            Mock -CommandName Remove-DSCPullServerESERecord

            Mock -CommandName PreProc -MockWith {
                $eseConnection
            }

            $registration | Remove-DSCPullServerAdminRegistration -WhatIf

            Assert-MockCalled -CommandName Get-DSCPullServerAdminRegistration -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerSQLCommand -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Remove-DSCPullServerESERecord -Exactly -Times 0 -Scope it
        }
    }
}
