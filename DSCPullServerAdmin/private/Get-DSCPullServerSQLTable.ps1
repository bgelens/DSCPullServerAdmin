function Get-DSCPullServerSQLTable {
    [CmdletBinding()]
    [Diagnostics.CodeAnalysis.SuppressMessage('PSAvoidUsingEmptyCatchBlock', '')]
    [Diagnostics.CodeAnalysis.SuppressMessage('PSUseOutputTypeCorrectly', '')]
    param (
        [Parameter(Mandatory)]
        [DSCPullServerSQLConnection] $Connection
    )
    try {
        $sqlConnection = [System.Data.SqlClient.SqlConnection]::new($Connection.ConnectionString())
        $sqlConnection.Open()
        $sqlConnection.GetSchema('Tables').TABLE_NAME
    } catch {
        Write-Error -ErrorRecord $_ -ErrorAction Stop
    } finally {
        $sqlConnection.Close()
        $sqlConnection.Dispose()
    }
}