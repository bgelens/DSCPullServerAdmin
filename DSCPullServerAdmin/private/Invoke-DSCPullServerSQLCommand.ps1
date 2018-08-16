function Invoke-DSCPullServerSQLCommand {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [DSCPullServerSQLConnection] $Connection,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string] $Script,

        [Parameter()]
        [ValidateSet('Get', 'Set')]
        [string] $CommandType = 'Get',

        [Parameter()]
        [uint16] $CommandTimeOut = 30,

        [Parameter(ValueFromRemainingArguments, DontShow)]
        $DroppedParams
    )
    begin {
        $sqlConnection = [System.Data.SqlClient.SqlConnection]::new($Connection.ConnectionString())
        try {
            $sqlConnection.Open()
        } catch {
            Write-Error -ErrorRecord $_ -ErrorAction Stop
        }
    }
    process {
        try {
            $command = $sqlConnection.CreateCommand()
            $command.CommandText = $Script
            $command.CommandTimeout = $CommandTimeOut

            Write-Verbose ("Invoking command: {0}" -f $Script)

            if ($CommandType -eq 'Get') {
                $command.ExecuteReader()
            } else {
                [void] $command.ExecuteNonQuery()
            }
        } catch {
            Write-Error -ErrorRecord $_ -ErrorAction Stop
        } finally {
            if ($false -eq $?) {
                $sqlConnection.Close()
                $sqlConnection.Dispose()
            }
        }
    }
    end {
        $sqlConnection.Close()
        $sqlConnection.Dispose()
    }
}
