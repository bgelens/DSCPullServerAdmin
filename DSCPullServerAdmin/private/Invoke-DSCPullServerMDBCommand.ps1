function Invoke-DSCPullServerMDBCommand {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [DSCPullServerMDBConnection] $Connection,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string] $Script,

        [Parameter()]
        [ValidateSet('Get', 'Set')]
        [string] $CommandType = 'Get',

        [Parameter(ValueFromRemainingArguments, DontShow)]
        $DroppedParams
    )
    begin {
        try {
            $mdbConnection = [System.Data.OleDb.OleDbConnection]::new($Connection.ConnectionString())
            $mdbConnection.Open()
        } catch {
            Write-Error -ErrorRecord $_ -ErrorAction Stop
        }
    }
    process {
        try {
            $command = $mdbConnection.CreateCommand()
            $command.CommandText = $Script

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
                $mdbConnection.Close()
                $mdbConnection.Dispose()
            }
        }
    }
    end {
        $mdbConnection.Close()
        $mdbConnection.Dispose()
    }
}
