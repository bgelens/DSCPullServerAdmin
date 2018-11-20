function Open-DSCPullServerTable {
    param (
        [Parameter(Mandatory)]
        [DSCPullServerESEConnection] $Connection,

        [Parameter(Mandatory)]
        [string] $Table
    )
    [Microsoft.Isam.Esent.Interop.JET_TABLEID] $tableId = [Microsoft.Isam.Esent.Interop.JET_TABLEID]::Nil
    [void] [Microsoft.Isam.Esent.Interop.Api]::JetOpenTable(
        $Connection.SessionId,
        $Connection.DbId,
        $Table,
        $null,
        0,
        [Microsoft.Isam.Esent.Interop.OpenTableGrbit]::None,
        [ref]$tableId
    )
    $Connection.TableId = $tableId
}
