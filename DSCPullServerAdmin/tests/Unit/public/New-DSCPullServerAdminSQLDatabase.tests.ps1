$here = $PSScriptRoot

$modulePath = "$here\..\..\.."
$moduleName = Split-Path -Path $modulePath -Leaf

InModuleScope $moduleName {
    Describe New-DSCPullServerAdminSQLDatabase {
        It 'Should write a warning when database already exists' {
            Mock -CommandName Test-DSCPullServerDatabaseExist -MockWith {
                $true
            }

            Mock -CommandName Write-Warning
            Mock -CommandName Invoke-DSCPullServerSQLCommand

            New-DSCPullServerAdminSQLDatabase -SQLServer 'Server\Instance' -Database 'DSCDB' -Credential ([pscredential]::Empty) -Confirm:$false

            Assert-MockCalled -CommandName Write-Warning -Exactly -Times 1 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerSQLCommand -Exactly -Times 0 -Scope it
        }

        It 'Should create a database when database does not already exists' {
            Mock -CommandName Test-DSCPullServerDatabaseExist -MockWith {
                $false
            }

            Mock -CommandName Write-Warning
            Mock -CommandName Invoke-DSCPullServerSQLCommand -MockWith {
                param (
                    $script
                )
                Write-Verbose -Message $Script -Verbose
            }

            $result = New-DSCPullServerAdminSQLDatabase -SQLServer 'Server\Instance' -Database 'DSCDB' -Confirm:$false 4>&1
            $result | Should -Not -BeNullOrEmpty

            Assert-MockCalled -CommandName Write-Warning -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerSQLCommand -Exactly -Times 4 -Scope it
        }

        It 'Should have ShouldProcess before calling Invoke-DSCPullServerSQLCommand' {
            Mock -CommandName Test-DSCPullServerDatabaseExist -MockWith {
                $false
            }

            Mock -CommandName Write-Warning
            Mock -CommandName Invoke-DSCPullServerSQLCommand

            New-DSCPullServerAdminSQLDatabase -SQLServer 'Server\Instance' -Database 'DSCDB' -Confirm:$false -WhatIf

            Assert-MockCalled -CommandName Write-Warning -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerSQLCommand -Exactly -Times 0 -Scope it
        }
    }
}
