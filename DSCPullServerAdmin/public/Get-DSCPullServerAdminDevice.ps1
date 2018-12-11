<#
    .SYNOPSIS
    Get device entries (LCMv1) from a Pull Server Database.

    .DESCRIPTION
    LCMv1 (WMF4 / PowerShell 4.0) pull clients send information
    to the Pull Server which stores their data in the devices table.
    This function will return devices from the devices table and allows
    for multiple types of filtering.

    .PARAMETER TargetName
    Return the device with the specific TargetName.
    Wildcards are supported for SQL and ESE connections but not for MDB connection.

    .PARAMETER ConfigurationID
    Return all devices with the same ConfigurationID.

    .PARAMETER Connection
    Accepts a specific Connection to be passed to target a specific database.
    When not specified, the currently Active Connection from memory will be used
    unless one off the parameters for ad-hoc connections (ESEFilePath, SQLServer)
    is used in which case, an ad-hoc connection is created.

    .PARAMETER ESEFilePath
    Define the EDB file path to use an ad-hoc ESE connection.

    .PARAMETER MDBFilePath
    Define the MDB file path to use an ad-hoc MDB connection.

    .PARAMETER SQLServer
    Define the SQL Instance to use in an ad-hoc SQL connection.

    .PARAMETER Credential
    Define the Credentials to use with an ad-hoc SQL connection.

    .PARAMETER Database
    Define the database to use with an ad-hoc SQL connection.

    .EXAMPLE
    Get-DSCPullServerAdminDevice -TargetName '192.168.0.1'

    .EXAMPLE
    Get-DSCPullServerAdminDevice
#>
function Get-DSCPullServerAdminDevice {
    [OutputType([DSCDevice])]
    [CmdletBinding(DefaultParameterSetName = 'Connection')]
    param (
        [Parameter()]
        [SupportsWildcards()]
        [ValidateNotNullOrEmpty()]
        [String] $TargetName,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [guid] $ConfigurationID,

        [Parameter(ParameterSetName = 'Connection')]
        [DSCPullServerConnection] $Connection = (Get-DSCPullServerAdminConnection -OnlyShowActive),

        [Parameter(Mandatory, ParameterSetName = 'ESE')]
        [ValidateScript({$_ | Assert-DSCPullServerDatabaseFilePath -Type 'ESE'})]
        [System.IO.FileInfo] $ESEFilePath,

        [Parameter(Mandatory, ParameterSetName = 'MDB')]
        [ValidateScript({$_ | Assert-DSCPullServerDatabaseFilePath -Type 'MDB'})]
        [System.IO.FileInfo] $MDBFilePath,

        [Parameter(Mandatory, ParameterSetName = 'SQL')]
        [ValidateNotNullOrEmpty()]
        [Alias('SQLInstance')]
        [string] $SQLServer,

        [Parameter(ParameterSetName = 'SQL')]
        [pscredential] $Credential,

        [Parameter(ParameterSetName = 'SQL')]
        [ValidateNotNullOrEmpty()]
        [string] $Database
    )

    begin {
        if ($null -ne $Connection -and -not $PSBoundParameters.ContainsKey('Connection')) {
            [void] $PSBoundParameters.Add('Connection', $Connection)
        }
        $Connection = PreProc -ParameterSetName $PSCmdlet.ParameterSetName @PSBoundParameters
        if ($null -eq $Connection) {
            break
        } else {
            $script:GetConnection = $Connection
        }
    }
    process {
        switch ($Connection.Type) {
            ESE {
                $eseParams = @{
                    Connection = $Connection
                    Table = 'Devices'
                }
                if ($PSBoundParameters.ContainsKey('TargetName')) {
                    $eseParams.Add('TargetName', $TargetName)
                }
                if ($PSBoundParameters.ContainsKey('ConfigurationID')) {
                    $eseParams.Add('ConfigurationID', $ConfigurationID)
                }

                Get-DSCPullServerESERecord @eseParams
            }
            SQL {
                $tsqlScript = 'SELECT * FROM Devices'
                $filters = [System.Collections.ArrayList]::new()
                if ($PSBoundParameters.ContainsKey("TargetName")) {
                    [void] $filters.Add(("TargetName like '{0}'" -f $TargetName.Replace('*', '%').Replace('?', '_')))
                }
                if ($PSBoundParameters.ContainsKey("ConfigurationID")) {
                    [void] $filters.Add(("ConfigurationID = '{0}'" -f $ConfigurationID))
                }

                if ($filters.Count -ge 1) {
                    $tsqlScript += " WHERE {0}" -f ($filters -join ' AND ')
                }

                Invoke-DSCPullServerSQLCommand -Connection $Connection -Script $tsqlScript | ForEach-Object {
                    try {
                        [DSCDevice]::New($_)
                    } catch {
                        Write-Error -ErrorRecord $_ -ErrorAction Continue
                    }
                }
            }
            MDB {
                $tsqlScript = 'SELECT * FROM Devices'
                $filters = [System.Collections.ArrayList]::new()
                if ($PSBoundParameters.ContainsKey("TargetName")) {
                    if ([System.Management.Automation.WildcardPattern]::ContainsWildcardCharacters($TargetName)) {
                        Write-Error -Message "MDB connection does not support wildcards for TargetName" -ErrorAction Stop
                    } else {
                        [void] $filters.Add(("TargetName = '{0}'" -f $TargetName))
                    }
                }
                if ($PSBoundParameters.ContainsKey("ConfigurationID")) {
                    [void] $filters.Add(("ConfigurationID = '{0}'" -f $ConfigurationID))
                }

                if ($filters.Count -ge 1) {
                    $tsqlScript += " WHERE {0}" -f ($filters -join ' AND ')
                }

                Invoke-DSCPullServerMDBCommand -Connection $Connection -Script $tsqlScript | ForEach-Object {
                    try {
                        [DSCDevice]::New($_)
                    } catch {
                        Write-Error -ErrorRecord $_ -ErrorAction Continue
                    }
                }
            }
        }
    }
    end {
        $script:GetConnection = $null
    }
}
