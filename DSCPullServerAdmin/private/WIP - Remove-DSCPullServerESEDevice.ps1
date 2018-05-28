function Remove-DSCPullServerESEDevice {
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [Parameter(Mandatory)]
        [DSCPullServerESEConnection] $Connection,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [Alias('Name')]
        [string] $TargetName,

        [switch] $CleanEmpty
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
            if ($CleanEmpty) {
                if ([string]::IsNullOrEmpty([Microsoft.Isam.Esent.Interop.Api]::RetrieveColumnAsString($Connection.SessionId, $tableId, $columnDictionary["TargetName"]))) {
                    [Microsoft.Isam.Esent.Interop.Api]::JetDelete($Connection.SessionId, $tableId)
                }
            }
            if ($TargetName -ne ([Microsoft.Isam.Esent.Interop.Api]::RetrieveColumnAsString($Connection.SessionId, $tableId, $columnDictionary["TargetName"]))) {
                continue
            } else {
                if ($PSCmdlet.ShouldProcess($TargetName)) {
                    [Microsoft.Isam.Esent.Interop.Api]::JetDelete($Connection.SessionId, $tableId)
                }
                break
            }
        }
    } catch {
        Write-Error -ErrorRecord $_ -ErrorAction Stop
    }
    finally {
        Dismount-DSCPullServerESEDatabase -Connection $Connection
    }
}
