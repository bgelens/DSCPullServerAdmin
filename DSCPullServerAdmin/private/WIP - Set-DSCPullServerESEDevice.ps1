function Set-DSCPullServerESEDevice {
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
        [Microsoft.Isam.Esent.Interop.Api]::MoveBeforeFirst($Connection.SessionId, $tableId)
        while ([Microsoft.Isam.Esent.Interop.Api]::TryMoveNext($Connection.SessionId, $tableId)) {
            if ($TargetName -ne ([Microsoft.Isam.Esent.Interop.Api]::RetrieveColumnAsString($Connection.SessionId, $tableId, $columnDictionary["TargetName"]))) {
                continue
            } else {
                $transAction = [Microsoft.Isam.Esent.Interop.Transaction]::new($Connection.SessionId)
                #[Microsoft.Isam.Esent.Interop.Api]::JetPrepareUpdate($Connection.SessionId, $tableId, [Microsoft.Isam.Esent.Interop.JET_prep]::Replace)
                
                
                $update = [Microsoft.Isam.Esent.Interop.Update]::new($Connection.SessionId, $tableId, [Microsoft.Isam.Esent.Interop.JET_prep]::Replace)

                if ($PSBoundParameters.ContainsKey('Dirty')) {
                    [Microsoft.Isam.Esent.Interop.Api]::SetColumn($Connection.SessionId, $tableId, $columnDictionary['Dirty'], $Dirty.ToByte($_))
                }

                #[Microsoft.Isam.Esent.Interop.Api]::SetColumn($Connection.SessionId, $tableId, $columnDictionary['ConfigurationId'], $ConfigurationId.ToString(), [System.Text.Encoding]::Unicode)
                #[Microsoft.Isam.Esent.Interop.Api]::SetColumn($Connection.SessionId, $tableId, $columnDictionary['ServerCheckSum'], $ServerCheckSum, [System.Text.Encoding]::Unicode)
                #[Microsoft.Isam.Esent.Interop.Api]::SetColumn($Connection.SessionId, $tableId, $columnDictionary['TargetCheckSum'], $TargetCheckSum, [System.Text.Encoding]::Unicode)
                #[Microsoft.Isam.Esent.Interop.Api]::SetColumn($Connection.SessionId, $tableId, $columnDictionary['NodeCompliant'], $NodeCompliant)
                #[Microsoft.Isam.Esent.Interop.Api]::SetColumn($Connection.SessionId, $tableId, $columnDictionary['LastComplianceTime'], $LastComplianceTime)
                #[Microsoft.Isam.Esent.Interop.Api]::SetColumn($Connection.SessionId, $tableId, $columnDictionary['LastHeartbeatTime'], $LastHeartbeatTime)
                #[Microsoft.Isam.Esent.Interop.Api]::SetColumn($Connection.SessionId, $tableId, $columnDictionary['Dirty'], $Dirty)
                #[Microsoft.Isam.Esent.Interop.Api]::SetColumn($Connection.SessionId, $tableId, $columnDictionary['StatusCode'], $StatusCode)
                $update.Save()
                #$transAction.Commit([Microsoft.Isam.Esent.Interop.CommitTransactionGrbit]::None)
                #[Microsoft.Isam.Esent.Interop.Api]::JetUpdate($Connection.SessionId, $tableId)
                $transAction.Commit([Microsoft.Isam.Esent.Interop.CommitTransactionGrbit]::None)
                #break
            }
        }
    } catch {
        $transAction.Dispose()
        Write-Error -ErrorRecord $_ -ErrorAction Stop
    }
    finally {
        Dismount-DSCPullServerESEDatabase -Connection $Connection
    }
}
