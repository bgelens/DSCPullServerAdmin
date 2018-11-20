function Test-DSCPullServerESEDatabase {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [DSCPullServerESEConnection] $Connection
    )
    $expectedTableNames = @(
        'Devices',
        'RegistrationData',
        'StatusReport'
    )

    $tableNames = Get-DSCPullServerESETable -Connection $connection
    Write-Verbose -Message "Database Tables: $($tableNames -join ', ' | Out-String)"

    $result = $true
    foreach ($table in $expectedTableNames) {
        if ($table -notin $tableNames) {
            $result = $false
        }
    }
    $result
}