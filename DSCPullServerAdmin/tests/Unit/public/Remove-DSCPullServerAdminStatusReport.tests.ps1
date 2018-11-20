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

    function GetReportFromEDB {
        $script:GetConnection = $eseConnection
        $report
    }

    Describe Remove-DSCPullServerAdminStatusReport {
        It 'Should remove a statusreport when it is passed in via InputObject (pipeline) SQL' {
            Mock -CommandName Get-DSCPullServerAdminStatusReport

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

            $result = $report | Remove-DSCPullServerAdminStatusReport -Confirm:$false 4>&1
            $result | Should -Not -BeNullOrEmpty

            Assert-MockCalled -CommandName Get-DSCPullServerAdminStatusReport -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerSQLCommand -Exactly -Times 1 -Scope it
            Assert-MockCalled -CommandName Remove-DSCPullServerESERecord -Exactly -Times 0 -Scope it
        }

        It 'Should remove a statusreport when it is passed in via InputObject (pipeline) ESE' {
            Mock -CommandName Get-DSCPullServerAdminStatusReport

            Mock -CommandName Invoke-DSCPullServerSQLCommand

            Mock -CommandName Remove-DSCPullServerESERecord

            Mock -CommandName PreProc -MockWith {
                $eseConnection
            }

            GetReportFromEDB | Remove-DSCPullServerAdminStatusReport -Confirm:$false 4>&1

            Assert-MockCalled -CommandName Get-DSCPullServerAdminStatusReport -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerSQLCommand -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Remove-DSCPullServerESERecord -Exactly -Times 1 -Scope it
        }

        It 'Should remove a statusreport when JobId was specified and statusreport was found (SQL)' {
            Mock -CommandName Get-DSCPullServerAdminStatusReport -MockWith {
                $report
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

            $result = Remove-DSCPullServerAdminStatusReport -JobId ([guid]::Empty) -Connection $sqlConnection -Confirm:$false 4>&1
            $result | Should -Not -BeNullOrEmpty

            Assert-MockCalled -CommandName Get-DSCPullServerAdminStatusReport -Exactly -Times 1 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerSQLCommand -Exactly -Times 1 -Scope it
            Assert-MockCalled -CommandName Remove-DSCPullServerESERecord -Exactly -Times 0 -Scope it
        }

        It 'Should remove a statusreport when JobId was specified and statusreport was found (ESE)' {
            Mock -CommandName Get-DSCPullServerAdminStatusReport -MockWith {
                $report
            }

            Mock -CommandName Invoke-DSCPullServerSQLCommand

            Mock -CommandName Remove-DSCPullServerESERecord

            Mock -CommandName PreProc -MockWith {
                $eseConnection
            }

            Remove-DSCPullServerAdminStatusReport -JobId ([guid]::Empty) -Connection $eseConnection -Confirm:$false 4>&1

            Assert-MockCalled -CommandName Get-DSCPullServerAdminStatusReport -Exactly -Times 2 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerSQLCommand -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Remove-DSCPullServerESERecord -Exactly -Times 1 -Scope it
        }

        It 'Should write a warning when JobId was specified but statusreport was not found (SQL)' {
            Mock -CommandName Get-DSCPullServerAdminStatusReport

            Mock -CommandName Invoke-DSCPullServerSQLCommand

            Mock -CommandName Write-Warning

            Mock -CommandName Remove-DSCPullServerESERecord

            Mock -CommandName PreProc -MockWith {
                $sqlConnection
            }

            Remove-DSCPullServerAdminStatusReport -JobId ([guid]::Empty)

            Assert-MockCalled -CommandName Get-DSCPullServerAdminStatusReport -Exactly -Times 1 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerSQLCommand -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Write-Warning -Exactly -Times 1 -Scope it
            Assert-MockCalled -CommandName Remove-DSCPullServerESERecord -Exactly -Times 0 -Scope it
        }

        It 'Should write a warning when JobId was specified but statusreport was not found (ESE)' {
            Mock -CommandName Get-DSCPullServerAdminStatusReport

            Mock -CommandName Invoke-DSCPullServerSQLCommand

            Mock -CommandName Write-Warning

            Mock -CommandName Remove-DSCPullServerESERecord

            Mock -CommandName PreProc -MockWith {
                $eseConnection
            }

            Remove-DSCPullServerAdminStatusReport -JobId ([guid]::Empty)

            Assert-MockCalled -CommandName Get-DSCPullServerAdminStatusReport -Exactly -Times 1 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerSQLCommand -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Write-Warning -Exactly -Times 1 -Scope it
            Assert-MockCalled -CommandName Remove-DSCPullServerESERecord -Exactly -Times 0 -Scope it
        }

        It 'Should have ShouldProcess before calling Invoke-DSCPullServerSQLCommand' {
            Mock -CommandName Get-DSCPullServerAdminStatusReport

            Mock -CommandName Invoke-DSCPullServerSQLCommand

            Mock -CommandName Remove-DSCPullServerESERecord

            Mock -CommandName PreProc -MockWith {
                $sqlConnection
            }

            $report | Remove-DSCPullServerAdminStatusReport -WhatIf

            Assert-MockCalled -CommandName Get-DSCPullServerAdminStatusReport -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerSQLCommand -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Remove-DSCPullServerESERecord -Exactly -Times 0 -Scope it
        }

        It 'Should have ShouldProcess before calling Remove-DSCPullServerESERecord' {
            Mock -CommandName Get-DSCPullServerAdminStatusReport

            Mock -CommandName Invoke-DSCPullServerSQLCommand

            Mock -CommandName Remove-DSCPullServerESERecord

            Mock -CommandName PreProc -MockWith {
                $eseConnection
            }

            $report | Remove-DSCPullServerAdminStatusReport -WhatIf

            Assert-MockCalled -CommandName Get-DSCPullServerAdminStatusReport -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Invoke-DSCPullServerSQLCommand -Exactly -Times 0 -Scope it
            Assert-MockCalled -CommandName Remove-DSCPullServerESERecord -Exactly -Times 0 -Scope it
        }
    }
}
