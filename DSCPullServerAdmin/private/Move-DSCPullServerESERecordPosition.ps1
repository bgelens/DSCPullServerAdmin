function Move-DSCPullServerESERecordPosition {
    [OutputType([bool])]
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [DSCPullServerESEConnection] $Connection,

        [Parameter(Mandatory)]
        [string] $Table,

        [Parameter(Mandatory)]
        [bool] $FirstMove
    )

    switch ($Table) {
        StatusReport {
            if ($FirstMove) {
                [Microsoft.Isam.Esent.Interop.Api]::TryMoveLast($Connection.SessionId, $Connection.TableId)
            } else {
                [Microsoft.Isam.Esent.Interop.Api]::TryMovePrevious($Connection.SessionId, $Connection.TableId)
            }
        }
        default {
            if ($FirstMove) {
                [Microsoft.Isam.Esent.Interop.Api]::TryMoveFirst($Connection.SessionId, $Connection.TableId)
            } else {
                [Microsoft.Isam.Esent.Interop.Api]::TryMoveNext($Connection.SessionId, $Connection.TableId)
            }
        }
    }
}
