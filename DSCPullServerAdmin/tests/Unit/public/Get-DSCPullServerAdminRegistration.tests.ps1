$here = $PSScriptRoot

$modulePath = "$here\..\..\.."
$moduleName = Split-Path -Path $modulePath -Leaf

InModuleScope $moduleName {
    $eseConnection = [DSCPullServerESEConnection]::new()
    $eseConnection.Index = 0
    $eseConnection.Active = $true

    $sqlConnection = [DSCPullServerSQLConnection]::new()
    $sqlConnection.Active = $true
    $sqlConnection.Index = 1

    Describe Get-DSCPullServerAdminRegistration {
        BeforeEach {
            $script:DSCPullServerConnections = $null
        }

        It 'Should Call Get-DSCPullServerESERegistration when Connection passed is ESE' {
            Mock -CommandName PreProc -MockWith {
                $eseConnection
            }

            Mock -CommandName Get-DSCPullServerESERegistration
            Mock -CommandName Invoke-DSCPullServerSQLCommand

            Get-DSCPullServerAdminRegistration -Connection $eseConnection

            Assert-MockCalled -CommandName Get-DSCPullServerESERegistration -Exactly -Times 1 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerSQLCommand -Exactly -Times 0 -Scope it
        }

        It 'Should Call Get-DSCPullServerESERegistration when active Connection is ESE' {
            $script:DSCPullServerConnections = [System.Collections.ArrayList]::new()
            [void] $script:DSCPullServerConnections.Add($eseConnection)

            Mock -CommandName PreProc -MockWith {
                $eseConnection
            }

            Mock -CommandName Get-DSCPullServerESERegistration
            Mock -CommandName Invoke-DSCPullServerSQLCommand

            Get-DSCPullServerAdminRegistration

            Assert-MockCalled -CommandName Get-DSCPullServerESERegistration -Exactly -Times 1 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerSQLCommand -Exactly -Times 0 -Scope it
        }

        It 'Should Call Get-DSCPullServerESERegistration with filters when active Connection is ESE and filters specified' {
            $script:DSCPullServerConnections = [System.Collections.ArrayList]::new()
            [void] $script:DSCPullServerConnections.Add($eseConnection)

            Mock -CommandName PreProc -MockWith {
                $eseConnection
            }

            Mock -CommandName Get-DSCPullServerESERegistration -MockWith {
                param (
                    $AgentId,
                    $NodeName
                )

                [pscustomobject]@{
                    AgentId = $AgentId
                    NodeName = $NodeName
                }
            }

            Mock -CommandName Invoke-DSCPullServerSQLCommand

            $result = Get-DSCPullServerAdminRegistration -AgentId ([guid]::Empty) -NodeName 'bogusNode'
            $result.AgentId | Should -Be ([guid]::Empty)
            $result.NodeName | Should -Be 'bogusNode'

            Assert-MockCalled -CommandName Get-DSCPullServerESERegistration -Exactly -Times 1 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerSQLCommand -Exactly -Times 0 -Scope it
        }

        It 'Should Call Invoke-DSCPullServerSQLCommand when Connection passed is SQL' {
            Mock -CommandName PreProc -MockWith {
                $sqlConnection
            }

            Mock -CommandName Get-DSCPullServerESERegistration
            Mock -CommandName Invoke-DSCPullServerSQLCommand

            Get-DSCPullServerAdminRegistration -Connection $sqlConnection

            Assert-MockCalled -CommandName Get-DSCPullServerESERegistration -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerSQLCommand -Exactly -Times 1 -Scope it
        }

        It 'Should Call Invoke-DSCPullServerSQLCommand when active Connection is SQL' {
            $script:DSCPullServerConnections = [System.Collections.ArrayList]::new()
            [void] $script:DSCPullServerConnections.Add($sqlConnection)

            Mock -CommandName PreProc -MockWith {
                $sqlConnection
            }

            Mock -CommandName Get-DSCPullServerESERegistration
            Mock -CommandName Invoke-DSCPullServerSQLCommand

            Get-DSCPullServerAdminRegistration

            Assert-MockCalled -CommandName Get-DSCPullServerESERegistration -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerSQLCommand -Exactly -Times 1 -Scope it
        }

        It 'Should Call Invoke-DSCPullServerSQLCommand with filters when active Connection is SQL and filters specified' {
            $script:DSCPullServerConnections = [System.Collections.ArrayList]::new()
            [void] $script:DSCPullServerConnections.Add($sqlConnection)

            Mock -CommandName PreProc -MockWith {
                $sqlConnection
            }

            Mock -CommandName Get-DSCPullServerESERegistration
            Mock -CommandName Invoke-DSCPullServerSQLCommand -MockWith {
                param (
                    $Script
                )
                Write-Verbose -Message $Script -Verbose
            }

            $result = Get-DSCPullServerAdminRegistration -AgentId ([guid]::Empty) -NodeName 'bogusNode' 4>&1
            $result | Should -Be "SELECT * FROM RegistrationData WHERE AgentId = '00000000-0000-0000-0000-000000000000' AND NodeName like 'bogusNode'"

            Assert-MockCalled -CommandName Get-DSCPullServerESERegistration -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerSQLCommand -Exactly -Times 1 -Scope it
        }

        It 'Should throw when Invoke-DSCPullServerSQLCommand result cannot be used to instantiate DSCRegistration object' {
            $script:DSCPullServerConnections = [System.Collections.ArrayList]::new()
            [void] $script:DSCPullServerConnections.Add($sqlConnection)

            Mock -CommandName PreProc -MockWith {
                $sqlConnection
            }

            Mock -CommandName Get-DSCPullServerESERegistration
            Mock -CommandName Invoke-DSCPullServerSQLCommand -MockWith {
                'invaliddata'
            }

            Mock -CommandName Write-Error

            Get-DSCPullServerAdminRegistration

            Assert-MockCalled -CommandName Get-DSCPullServerESERegistration -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerSQLCommand -Exactly -Times 1 -Scope it
            Assert-MockCalled -CommandName Write-Error -Exactly -Times 1 -Scope it
        }
    }
}
