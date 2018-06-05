function Test-DSCPullServerDatabaseExist {
    [OutputType([bool])]
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ParameterSetName = 'SQL')]
        [ValidateNotNullOrEmpty()]
        [string] $SQLServer,

        [Parameter(ParameterSetName = 'SQL')]
        [pscredential] $Credential,

        [Parameter(Mandatory, ParameterSetName = 'SQL')]
        [ValidateNotNullOrEmpty()]
        [Alias('Database')]
        [string] $Name,

        [Parameter(ParameterSetName = 'Connection')]
        [DSCPullServerSQLConnection] $Connection,

        [Parameter(ValueFromRemainingArguments)]
        $DroppedParams
    )
    if ($PSCmdlet.ParameterSetName -eq 'SQL') {
        $testConnection = [DSCPullServerSQLConnection]::new($SQLServer)
        if ($PSBoundParameters.ContainsKey('Credential')) {
            $testConnection.Credential = $Credential
        }
    } else {
        $testConnection = [DSCPullServerSQLConnection]::new($Connection.SQLServer)
        if ($null -ne $Connection.Credential) {
            $testConnection.Credential = $Connection.Credential
        }
        $Name = $Connection.Database
    }

    $testDBQuery = "DECLARE @dbname nvarchar(128) SET @dbname = N'{0}' IF (EXISTS (SELECT name FROM master.dbo.sysdatabases WHERE ('[' + name + ']' = @dbname OR name = @dbname))) SELECT CAST(1 AS bit) ELSE SELECT CAST(0 AS bit)" -f $Name
    $testResult = Invoke-DSCPullServerSQLCommand -Connection $testConnection -CommandType Get -Script $testDBQuery
    $testResult.GetBoolean(0)
}
