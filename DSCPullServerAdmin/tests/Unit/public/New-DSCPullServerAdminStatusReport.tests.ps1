$here = $PSScriptRoot

$modulePath = "$here\..\..\.."
$moduleName = Split-Path -Path $modulePath -Leaf

InModuleScope $moduleName {
    $sqlConnection = [DSCPullServerSQLConnection]::new()
    $sqlConnection.Active = $true
    $sqlConnection.Index = 0

    $eseConnection = [DSCPullServerESEConnection]::new()
    $eseConnection.Index = 1

    $report = [DSCNodeStatusReport]::new()
    $report.Id = [guid]::Empty
    $report.JobId = [guid]::Empty

    Describe New-DSCPullServerAdminStatusReport {
        It 'Should create a statusreport when JobId specified did not result in statusreport already found (SQL)' {
            Mock -CommandName Get-DSCPullServerAdminStatusReport

            Mock -CommandName Invoke-DSCPullServerSQLCommand -MockWith {
                param (
                    $script
                )
                Write-Verbose -Message $Script -Verbose
            }

            Mock -CommandName PreProc -MockWith {
                $sqlConnection
            }

            Mock -CommandName Mount-DSCPullServerESEDatabase
            Mock -CommandName Open-DSCPullServerTable
            Mock -CommandName Set-DSCPullServerESERecord
            Mock -CommandName Dismount-DSCPullServerESEDatabase

            New-DSCPullServerAdminStatusReport -JobId ([guid]::Empty) 4>&1

            Assert-MockCalled -CommandName Get-DSCPullServerAdminStatusReport -Exactly -Times 1 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerSQLCommand -Exactly -Times 1 -Scope it
            Assert-MockCalled -CommandName Mount-DSCPullServerESEDatabase -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Open-DSCPullServerTable -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Set-DSCPullServerESERecord -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Dismount-DSCPullServerESEDatabase -Exactly -Times 0 -Scope it
        }

        It 'Should create a statusreport when JobId specified did not result in statusreport already found (ESE)' {
            Mock -CommandName Get-DSCPullServerAdminStatusReport

            Mock -CommandName Invoke-DSCPullServerSQLCommand

            Mock -CommandName PreProc -MockWith {
                $eseConnection
            }

            Mock -CommandName Mount-DSCPullServerESEDatabase
            Mock -CommandName Open-DSCPullServerTable
            Mock -CommandName Set-DSCPullServerESERecord
            Mock -CommandName Dismount-DSCPullServerESEDatabase

            New-DSCPullServerAdminStatusReport -JobId ([guid]::Empty) 4>&1

            Assert-MockCalled -CommandName Get-DSCPullServerAdminStatusReport -Exactly -Times 1 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerSQLCommand -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Mount-DSCPullServerESEDatabase -Exactly -Times 1 -Scope it
            Assert-MockCalled -CommandName Open-DSCPullServerTable -Exactly -Times 1 -Scope it
            Assert-MockCalled -CommandName Set-DSCPullServerESERecord -Exactly -Times 1 -Scope it
            Assert-MockCalled -CommandName Dismount-DSCPullServerESEDatabase -Exactly -Times 1 -Scope it
        }

        It 'Should throw when JobId resulted in existing statusreport' {
            Mock -CommandName Get-DSCPullServerAdminStatusReport -MockWith {
                $report
            }

            Mock -CommandName Invoke-DSCPullServerSQLCommand

            Mock -CommandName PreProc -MockWith {
                $sqlConnection
            }

            Mock -CommandName Mount-DSCPullServerESEDatabase
            Mock -CommandName Open-DSCPullServerTable
            Mock -CommandName Set-DSCPullServerESERecord
            Mock -CommandName Dismount-DSCPullServerESEDatabase

            { New-DSCPullServerAdminStatusReport -JobId ([guid]::Empty) } |
                Should -Throw

            Assert-MockCalled -CommandName Get-DSCPullServerAdminStatusReport -Exactly -Times 1 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerSQLCommand -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Mount-DSCPullServerESEDatabase -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Open-DSCPullServerTable -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Set-DSCPullServerESERecord -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Dismount-DSCPullServerESEDatabase -Exactly -Times 0 -Scope it
        }

        It 'Should have ShouldProcess before calling Invoke-DSCPullServerSQLCommand' {
            Mock -CommandName Get-DSCPullServerAdminStatusReport
        
            Mock -CommandName Invoke-DSCPullServerSQLCommand

            Mock -CommandName PreProc -MockWith {
                $sqlConnection
            }

            Mock -CommandName Mount-DSCPullServerESEDatabase
            Mock -CommandName Open-DSCPullServerTable
            Mock -CommandName Set-DSCPullServerESERecord
            Mock -CommandName Dismount-DSCPullServerESEDatabase
        
            New-DSCPullServerAdminStatusReport -JobId ([guid]::Empty) -Connection $sqlConnection -WhatIf
        
            Assert-MockCalled -CommandName Get-DSCPullServerAdminStatusReport -Exactly -Times 1 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerSQLCommand -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Mount-DSCPullServerESEDatabase -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Open-DSCPullServerTable -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Set-DSCPullServerESERecord -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Dismount-DSCPullServerESEDatabase -Exactly -Times 0 -Scope it
        }

        It 'Should have ShouldProcess before calling Set-DSCPullServerESERecord' {
            Mock -CommandName Get-DSCPullServerAdminStatusReport
        
            Mock -CommandName Invoke-DSCPullServerSQLCommand

            Mock -CommandName PreProc -MockWith {
                $eseConnection
            }

            Mock -CommandName Mount-DSCPullServerESEDatabase
            Mock -CommandName Open-DSCPullServerTable
            Mock -CommandName Set-DSCPullServerESERecord
            Mock -CommandName Dismount-DSCPullServerESEDatabase
        
            New-DSCPullServerAdminStatusReport -JobId ([guid]::Empty) -Connection $eseConnection -WhatIf
        
            Assert-MockCalled -CommandName Get-DSCPullServerAdminStatusReport -Exactly -Times 1 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerSQLCommand -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Mount-DSCPullServerESEDatabase -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Open-DSCPullServerTable -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Set-DSCPullServerESERecord -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Dismount-DSCPullServerESEDatabase -Exactly -Times 0 -Scope it
        }

        It 'Should throw and dismount ESE Database when something goes wrong in DB operations' {
            Mock -CommandName Get-DSCPullServerAdminStatusReport
        
            Mock -CommandName Invoke-DSCPullServerSQLCommand

            Mock -CommandName PreProc -MockWith {
                $eseConnection
            }

            Mock -CommandName Write-Error

            Mock -CommandName Mount-DSCPullServerESEDatabase
            Mock -CommandName Open-DSCPullServerTable -MockWith {
                throw 'Error opening Table'
            }
            Mock -CommandName Set-DSCPullServerESERecord
            Mock -CommandName Dismount-DSCPullServerESEDatabase
        
            New-DSCPullServerAdminStatusReport -JobId ([guid]::Empty)
        
            Assert-MockCalled -CommandName Get-DSCPullServerAdminStatusReport -Exactly -Times 1 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerSQLCommand -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Mount-DSCPullServerESEDatabase -Exactly -Times 1 -Scope it
            Assert-MockCalled -CommandName Open-DSCPullServerTable -Exactly -Times 1 -Scope it
            Assert-MockCalled -CommandName Set-DSCPullServerESERecord -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Dismount-DSCPullServerESEDatabase -Exactly -Times 1 -Scope it
            Assert-MockCalled -CommandName Write-Error -Exactly -Times 1 -Scope it
        }
    }
}
