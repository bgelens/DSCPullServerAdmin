$here = $PSScriptRoot

$modulePath = "$here\..\..\.."
$moduleName = Split-Path -Path $modulePath -Leaf

InModuleScope $moduleName {
    $sqlConnection = [DSCPullServerSQLConnection]::new()
    $sqlConnection.Active = $true
    $sqlConnection.Index = 0

    $script:DSCPullServerConnections = [System.Collections.ArrayList]::new()
    [void] $script:DSCPullServerConnections.Add($sqlConnection)

    $registration = [DSCNodeRegistration]::new()
    $registration.AgentId = [guid]::Empty

    Describe Remove-DSCPullServerAdminRegistration {
        Mock -CommandName PreProc -MockWith {
            $sqlConnection
        }

        It 'Should remove a registration when it is passed in via InputObject (pipeline)' {
            Mock -CommandName Get-DSCPullServerAdminRegistration

            Mock -CommandName Invoke-DSCPullServerSQLCommand -MockWith {
                param (
                    $script
                )
                Write-Verbose -Message $Script -Verbose
            }

            $result = $registration | Remove-DSCPullServerAdminRegistration -Confirm:$false 4>&1
            $result | Should -Not -BeNullOrEmpty

            Assert-MockCalled -CommandName Get-DSCPullServerAdminRegistration -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerSQLCommand -Exactly -Times 1 -Scope it
        }

        It 'Should remove a registration when AgentId was specified and registration was found' {
            Mock -CommandName Get-DSCPullServerAdminRegistration -MockWith {
                $registration
            }

            Mock -CommandName Invoke-DSCPullServerSQLCommand -MockWith {
                param (
                    $script
                )
                Write-Verbose -Message $Script -Verbose
            }

            $result = Remove-DSCPullServerAdminRegistration -AgentId ([guid]::Empty) -Confirm:$false 4>&1
            $result | Should -Not -BeNullOrEmpty

            Assert-MockCalled -CommandName Get-DSCPullServerAdminRegistration -Exactly -Times 1 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerSQLCommand -Exactly -Times 1 -Scope it
        }

        It 'Should write a warning when AgentId was specified but registration was not found' {
            Mock -CommandName Get-DSCPullServerAdminRegistration

            Mock -CommandName Invoke-DSCPullServerSQLCommand

            Mock -CommandName Write-Warning

            Remove-DSCPullServerAdminRegistration -AgentId ([guid]::Empty)

            Assert-MockCalled -CommandName Get-DSCPullServerAdminRegistration -Exactly -Times 1 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerSQLCommand -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Write-Warning -Exactly -Times 1 -Scope it
        }

        It 'Should have ShouldProcess before calling Invoke-DSCPullServerSQLCommand' {
            Mock -CommandName Get-DSCPullServerAdminRegistration

            Mock -CommandName Invoke-DSCPullServerSQLCommand

            $registration | Remove-DSCPullServerAdminRegistration -WhatIf

            Assert-MockCalled -CommandName Get-DSCPullServerAdminRegistration -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerSQLCommand -Exactly -Times 0 -Scope it
        }
    }
}
