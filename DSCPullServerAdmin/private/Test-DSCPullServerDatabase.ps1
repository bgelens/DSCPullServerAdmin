function Test-DSCPullServerDatabase {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [DSCPullServerConnection] $Connection
    )
    $expectedTableNames = @(
        'Devices',
        'RegistrationData',
        'StatusReport'
    )

    $tableNames = switch ($Connection.Type) {
        SQL {
            Get-DSCPullServerSQLTable -Connection $connection
        }
        ESE {
            Get-DSCPullServerESETable -Connection $connection
        }
        MDB {
            Get-DSCPullServerMDBTable -Connection $connection
        }
    }
    Write-Verbose -Message "Database Tables: $($tableNames -join ', ' | Out-String)"

    $result = $true
    foreach ($table in $expectedTableNames) {
        if ($table -notin $tableNames) {
            $result = $false
        }
    }
    $result
}