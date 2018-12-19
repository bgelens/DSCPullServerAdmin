function Get-DSCPullServerMDBTable {
    [CmdletBinding()]
    [Diagnostics.CodeAnalysis.SuppressMessage('PSAvoidUsingEmptyCatchBlock', '')]
    [Diagnostics.CodeAnalysis.SuppressMessage('PSUseOutputTypeCorrectly', '')]
    param (
        [Parameter(Mandatory)]
        [DSCPullServerMDBConnection] $Connection
    )
    try {
        $mdbConnection = [System.Data.OleDb.OleDbConnection]::new($Connection.ConnectionString())
        $mdbConnection.Open()
        $mdbConnection.GetSchema('Tables').TABLE_NAME
    } catch {
        Write-Error -ErrorRecord $_ -ErrorAction Stop
    } finally {
        $mdbConnection.Close()
        $mdbConnection.Dispose()
    }
}