function Get-DSCPullServerESETable {
    [CmdletBinding()]
    [Diagnostics.CodeAnalysis.SuppressMessage('PSAvoidUsingEmptyCatchBlock', '')]
    [Diagnostics.CodeAnalysis.SuppressMessage('PSUseOutputTypeCorrectly', '')]
    param (
        [Parameter(Mandatory)]
        [DSCPullServerESEConnection] $Connection
    )
    try {
        Mount-DSCPullServerESEDatabase -Connection $Connection -Mode None
        [Microsoft.Isam.Esent.Interop.Api]::GetTableNames($Connection.SessionId, $Connection.DbId)
        Dismount-DSCPullServerESEDatabase -Connection $Connection
    } catch {}
}