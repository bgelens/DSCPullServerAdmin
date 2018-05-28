function New-DSCPullServerESEDevice {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [DSCPullServerESEConnection] $Connection,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [Alias('Name')]
        [string] $TargetName,

        [Parameter()]
        [guid] $ConfigurationID = [guid]::Empty,

        [Parameter()]
        [string] $ServerCheckSum,

        [Parameter()]
        [string] $TargetCheckSum,

        [Parameter()]
        [bool] $NodeCompliant = $false,

        [Parameter()]
        [datetime] $LastComplianceTime,

        [Parameter()]
        [datetime] $LastHeartbeatTime,

        [Parameter()]
        [bool] $Dirty = $false,

        [Parameter()]
        [int] $StatusCode
    )
    $table = 'Devices'
    [Microsoft.Isam.Esent.Interop.JET_TABLEID] $tableId = [Microsoft.Isam.Esent.Interop.JET_TABLEID]::Nil
    try {
        Mount-DSCPullServerESEDatabase -Connection $Connection -Mode None
        [void] [Microsoft.Isam.Esent.Interop.Api]::JetOpenTable(
            $Connection.SessionId,
            $Connection.DbId,
            $Table,
            $null,
            0,
            [Microsoft.Isam.Esent.Interop.OpenTableGrbit]::Updatable,
            [ref]$tableId
        )
    } catch {
        Write-Error -ErrorRecord $_ -ErrorAction Stop
    }

    try {
        $columnDictionary = [Microsoft.Isam.Esent.Interop.Api]::GetColumnDictionary($Connection.SessionId, $tableId)
        $transAction = [Microsoft.Isam.Esent.Interop.Transaction]::new($Connection.SessionId)
        $update = [Microsoft.Isam.Esent.Interop.Update]::new($Connection.SessionId, $tableId, [Microsoft.Isam.Esent.Interop.JET_prep]::Insert)
        [void] [Microsoft.Isam.Esent.Interop.Api]::SetColumn($Connection.SessionId, $tableId, $columnDictionary['TargetName'], $TargetName, [System.Text.Encoding]::Unicode)
        [void] [Microsoft.Isam.Esent.Interop.Api]::SetColumn($Connection.SessionId, $tableId, $columnDictionary['ConfigurationId'], $ConfigurationId.ToString(), [System.Text.Encoding]::Unicode)
        [void] [Microsoft.Isam.Esent.Interop.Api]::SetColumn($Connection.SessionId, $tableId, $columnDictionary['ServerCheckSum'], $ServerCheckSum, [System.Text.Encoding]::Unicode)
        [void] [Microsoft.Isam.Esent.Interop.Api]::SetColumn($Connection.SessionId, $tableId, $columnDictionary['TargetCheckSum'], $TargetCheckSum, [System.Text.Encoding]::Unicode)
        [void] [Microsoft.Isam.Esent.Interop.Api]::SetColumn($Connection.SessionId, $tableId, $columnDictionary['NodeCompliant'], $NodeCompliant)
        [void] [Microsoft.Isam.Esent.Interop.Api]::SetColumn($Connection.SessionId, $tableId, $columnDictionary['LastComplianceTime'], $LastComplianceTime)
        [void] [Microsoft.Isam.Esent.Interop.Api]::SetColumn($Connection.SessionId, $tableId, $columnDictionary['LastHeartbeatTime'], $LastHeartbeatTime)
        [void] [Microsoft.Isam.Esent.Interop.Api]::SetColumn($Connection.SessionId, $tableId, $columnDictionary['Dirty'], $Dirty)
        [void] [Microsoft.Isam.Esent.Interop.Api]::SetColumn($Connection.SessionId, $tableId, $columnDictionary['StatusCode'], $StatusCode)
        $update.Save()
        $transAction.Commit([Microsoft.Isam.Esent.Interop.CommitTransactionGrbit]::None)
    } catch {
        $transAction.Dispose()
        Write-Error -ErrorRecord $_ -ErrorAction Stop
    }
    finally {
        Dismount-DSCPullServerESEDatabase -Connection $Connection
    }
}
