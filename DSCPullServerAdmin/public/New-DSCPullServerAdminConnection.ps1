<#
    .SYNOPSIS
    Create a new connection with either a SQL Database or EDB file.

    .DESCRIPTION
    This function is used to create new connections for either SQL Databases
    or EDB files that are re-used for multiple tasks. More than one connection can
    be created in a PowerShell session. By default, connections are stored in memory
    and are visible via the Get-DSCPullServerAdminConnection function.
    Connections can be passed to other functions via parameter binding.
    The default connection is used by default for all other functions. The default
    connection can be modified with the Set-DSCPullServerAdminConnectionActive
    function.

    .PARAMETER ESEFilePath
    Specifies the path to the EDB file to be used for the connection.

    .PARAMETER SQLServer
    Specifies the SQL Instance to connect to for the connection.

    .PARAMETER Credential
    Specifies optional Credentials to use when connecting to the SQL Instance.

    .PARAMETER Database
    Specifies the Database name to use for the SQL connection.

    .PARAMETER DontStore
    When specified, the connection will not be stored in memory.

    .EXAMPLE
    New-DSCPullServerAdminConnection -ESEFilePath C:\Users\EDB\Devices.edb

    .EXAMPLE
    $sqlCredential = Get-Credential
    New-DSCPullServerAdminConnection -SQLServer sqlserver\instance -Database dscpulldb -Credential $sqlCredential
#>
function New-DSCPullServerAdminConnection {
    [Diagnostics.CodeAnalysis.SuppressMessage('PSUseShouldProcessForStateChangingFunctions', '')]
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
        if (-not (Test-DSCPullServerESEDatabase -Connection $connection)) {
            Write-Error -Message "Database $ESEFilePath is an invalid PullServer Database" -ErrorAction Stop
        }
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
