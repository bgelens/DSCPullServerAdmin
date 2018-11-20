function Dismount-DSCPullServerESEDatabase {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [DSCPullServerESEConnection] $Connection
    )

    [void] [Microsoft.Isam.Esent.Interop.Api]::JetCloseDatabase(
        $Connection.SessionId,
        $Connection.DbId,
        [Microsoft.Isam.Esent.Interop.CloseDatabaseGrbit]::None
    )

    [void] [Microsoft.Isam.Esent.Interop.Api]::JetDetachDatabase(
        $Connection.SessionId,
        $Connection.ESEFilePath
    )

    [void] [Microsoft.Isam.Esent.Interop.Api]::JetEndSession(
        $Connection.SessionId,
        [Microsoft.Isam.Esent.Interop.EndSessionGrbit]::None
    )

    [void] [Microsoft.Isam.Esent.Interop.Api]::JetTerm(
        $Connection.Instance
    )

    $Connection.Instance = $null
    $Connection.SessionId = $null
    $Connection.DbId = $null
    $Connection.TableId = $null
}
