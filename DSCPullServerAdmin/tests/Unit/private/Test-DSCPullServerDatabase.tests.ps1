$here = $PSScriptRoot

$modulePath = "$here\..\..\.."
$moduleName = Split-Path -Path $modulePath -Leaf

InModuleScope $moduleName {
    Describe Test-DSCPullServerDatabase {
        $eseConnection = [DSCPullServerESEConnection]::new()
        $eseConnection.Index = 0

        $sqlConnection = [DSCPullServerSQLConnection]::new()
        $sqlConnection.Active = $true
        $sqlConnection.Index = 1

        $mdbConnection = [DSCPullServerMDBConnection]::new()
        $mdbConnection.Active = $true
        $mdbConnection.Index = 2

        It 'Should result in True when edb database contains expected tables' {
            Mock -CommandName Get-DSCPullServerESETable -MockWith {
                @(
                    'Devices',
                    'RegistrationData',
                    'StatusReport' 
                )
            }

            Test-DSCPullServerDatabase -Connection $eseConnection |
                Should -BeTrue
        }

        It 'Should result in False when edb database does not contains expected tables' {
            Mock -CommandName Get-DSCPullServerESETable -MockWith {
                @(
                    'bogusTable'
                )
            }

            Test-DSCPullServerDatabase -Connection $eseConnection |
                Should -BeFalse
        }

        It 'Should result in True when mdb database contains expected tables' {
            Mock -CommandName Get-DSCPullServerMDBTable -MockWith {
                @(
                    'Devices',
                    'RegistrationData',
                    'StatusReport' 
                )
            }

            Test-DSCPullServerDatabase -Connection $mdbConnection |
                Should -BeTrue
        }

        It 'Should result in False when mdb database does not contains expected tables' {
            Mock -CommandName Get-DSCPullServerMDBTable -MockWith {
                @(
                    'bogusTable'
                )
            }

            Test-DSCPullServerDatabase -Connection $mdbConnection |
                Should -BeFalse
        }

        It 'Should result in True when sql database contains expected tables' {
            Mock -CommandName Get-DSCPullServerSQLTable -MockWith {
                @(
                    'Devices',
                    'RegistrationData',
                    'StatusReport' 
                )
            }

            Test-DSCPullServerDatabase -Connection $sqlConnection |
                Should -BeTrue
        }

        It 'Should result in False when sql database does not contains expected tables' {
            Mock -CommandName Get-DSCPullServerSQLTable -MockWith {
                @(
                    'bogusTable'
                )
            }

            Test-DSCPullServerDatabase -Connection $sqlConnection |
                Should -BeFalse
        }
    }
}
