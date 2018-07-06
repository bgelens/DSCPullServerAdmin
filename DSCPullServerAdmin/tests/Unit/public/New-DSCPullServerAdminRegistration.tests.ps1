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

    Describe New-DSCPullServerAdminRegistration {
        Mock -CommandName PreProc -MockWith {
            $sqlConnection
        }

        It 'Should create a registration when AgentId specified did not result in registration already found' {
            Mock -CommandName Get-DSCPullServerAdminRegistration

            Mock -CommandName Invoke-DSCPullServerSQLCommand -MockWith {
                param (
                    $script
                )
                Write-Verbose -Message $Script -Verbose
            }

            New-DSCPullServerAdminRegistration -AgentId ([guid]::Empty) -ConfigurationNames 'bogusConfig' -NodeName 'bogusNode' 4>&1

            Assert-MockCalled -CommandName Get-DSCPullServerAdminRegistration -Exactly -Times 1 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerSQLCommand -Exactly -Times 1 -Scope it
        }

        It 'Should throw when AgentId resulted in existing registration' {
            Mock -CommandName Get-DSCPullServerAdminRegistration -MockWith {
                $registration
            }

            Mock -CommandName Invoke-DSCPullServerSQLCommand

            { New-DSCPullServerAdminRegistration -AgentId ([guid]::Empty) -ConfigurationNames 'bogusConfig' -NodeName 'bogusNode' } |
                Should -Throw

            Assert-MockCalled -CommandName Get-DSCPullServerAdminRegistration -Exactly -Times 1 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerSQLCommand -Exactly -Times 0 -Scope it
        }

        It 'Should have ShouldProcess before calling Invoke-DSCPullServerSQLCommand' {
            Mock -CommandName Get-DSCPullServerAdminRegistration
        
            Mock -CommandName Invoke-DSCPullServerSQLCommand
        
            New-DSCPullServerAdminRegistration -AgentId ([guid]::Empty) -ConfigurationNames 'bogusConfig' -NodeName 'bogusNode' -WhatIf
        
            Assert-MockCalled -CommandName Get-DSCPullServerAdminRegistration -Exactly -Times 1 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerSQLCommand -Exactly -Times 0 -Scope it
        }
    }
}
