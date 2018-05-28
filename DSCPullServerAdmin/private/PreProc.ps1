function PreProc {
    param (
        [Parameter(Mandatory)]
        [string] $ParameterSetName,

        [DSCPullServerConnection] $Connection,

        [string] $SQLServer,

        [pscredential] $Credential,

        [string] $Database,

        [string] $ESEFilePath,

        [Parameter(ValueFromRemainingArguments)]
        $DroppedParams
    )

    switch -Wildcard ($ParameterSetName) {
        *Connection {
            if (Test-DefaultDSCPullServerConnection $Connection) {
                return $Connection
            }
        }
        *SQL {
            $newSQLArgs = @{
                SQLServer = $SQLServer
                DontStore = $true
            }

            $PSBoundParameters.Keys | ForEach-Object -Process {
                if ($_ -in 'Credential', 'Database') {
                    [void] $newSQLArgs.Add($_, $PSBoundParameters[$_])
                }
            }
            New-DSCPullServerAdminConnection @newSQLArgs
        }
        *ESE {
            $newESEArgs = @{
                ESEFilePath = $ESEFilePath
                DontStore = $true
            }
            New-DSCPullServerAdminConnection @newESEArgs
        }
    }
}
