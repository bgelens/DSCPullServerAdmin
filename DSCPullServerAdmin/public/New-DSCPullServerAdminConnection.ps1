function New-DSCPullServerAdminConnection {
    [OutputType([DSCPullServerSQLConnection])]
    [OutputType([DSCPullServerESEConnection])]
    [CmdletBinding(DefaultParameterSetName = 'SQL')]
    param (
        [Parameter(Mandatory, ParameterSetName = 'ESE')]
        [ValidateNotNullOrEmpty()]
        [string] $ESEFilePath,

        [Parameter(ParameterSetName = 'SQL')]
        [ValidateNotNullOrEmpty()]
        [Alias('SQLInstance')]
        [string] $SQLServer,

        [Parameter(ParameterSetName = 'SQL')]
        [pscredential] $Credential,

        [Parameter(ParameterSetName = 'SQL')]
        [ValidateNotNullOrEmpty()]
        [string] $Database,

        [switch] $DontStore
    )

    $currentConnections = Get-DSCPullServerAdminConnection
    $lastIndex = $currentConnections |
        Sort-Object -Property Index -Descending |
        Select-Object -First 1 -ExpandProperty Index

    if ($PSCmdlet.ParameterSetName -eq 'SQL') {
        if ($PSBoundParameters.ContainsKey('Credential') -and $PSBoundParameters.ContainsKey('Database')) {
            $connection = [DSCPullServerSQLConnection]::New($SQLServer, $Credential, $Database)
        } elseif ($PSBoundParameters.ContainsKey('Database')) {
            $connection = [DSCPullServerSQLConnection]::New($SQLServer, $Database)
        } elseif ($PSBoundParameters.ContainsKey('Credential')) {
            $connection = [DSCPullServerSQLConnection]::New($SQLServer, $Credential)
        } else {
            $connection = [DSCPullServerSQLConnection]::New($SQLServer)
        }
        if (-not (Test-DSCPullServerDatabaseExist -Connection $connection)) {
            Write-Error -Message "Could not find database with name $($connection.Database) at $($connection.SQLServer)" -ErrorAction Stop
        }
    } else {
        $connection = [DSCPullServerESEConnection]::New($ESEFilePath)
    }

    if (-not $DontStore) {
        if ($null -eq $currentConnections) {
            $connection.Index = 0
            $connection.Active = $true
        } else {
            $connection.Index = $lastIndex + 1
            $connection.Active = $false
        }
        if($null -eq $script:DSCPullServerConnections) {
            $script:DSCPullServerConnections = [System.Collections.ArrayList]::new()
        }
        [void] $script:DSCPullServerConnections.Add($connection)
    }
    $connection
}
