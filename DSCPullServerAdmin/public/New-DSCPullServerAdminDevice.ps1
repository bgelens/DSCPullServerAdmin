<#
    .SYNOPSIS
    Create device entries (LCMv1) in a Pull Server Database.

    .DESCRIPTION
    LCMv1 (WMF4 / PowerShell 4.0) pull clients send information
    to the Pull Server which stores their data in the devices table.
    This function will allow for manual creation of devices in the
    devices table and allows for multiple properties to be set.

    .PARAMETER ConfigurationID
    Set the ConfigurationID property for the new device.

    .PARAMETER TargetName
    Set the TargetName property for the new device.

    .PARAMETER ServerCheckSum
    Set the ServerCheckSum property for the new device.

    .PARAMETER TargetCheckSum
    Set the TargetCheckSum property for the new device.

    .PARAMETER NodeCompliant
    Set the NodeCompliant property for the new device.

    .PARAMETER LastComplianceTime
    Set the LastComplianceTime property for the new device.

    .PARAMETER LastHeartbeatTime
    Set the LastHeartbeatTime property for the new device.

    .PARAMETER Dirty
    Set the Dirty property for the new device.

    .PARAMETER StatusCode
    Set the StatusCode property for the new device.

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
    New-DSCPullServerAdminDevice -ConfigurationID '80ee20f9-78df-480d-8175-9dd6cb09607a' -TargetName '192.168.0.1'
#>
function New-DSCPullServerAdminDevice {
    [CmdletBinding(
        DefaultParameterSetName = 'Connection',
        ConfirmImpact = 'Medium',
        SupportsShouldProcess
    )]
    param (
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [guid] $ConfigurationID,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [string] $TargetName,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [string] $ServerCheckSum,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [string] $TargetCheckSum,

        [Parameter(ValueFromPipelineByPropertyName)]
        [bool] $NodeCompliant,

        [Parameter(ValueFromPipelineByPropertyName)]
        [nullable[datetime]] $LastComplianceTime,

        [Parameter(ValueFromPipelineByPropertyName)]
        [nullable[datetime]] $LastHeartbeatTime,

        [Parameter(ValueFromPipelineByPropertyName)]
        [bool] $Dirty,

        [Parameter(ValueFromPipelineByPropertyName)]
        [uint32] $StatusCode,

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
        [string] $Database
    )
    begin {
        if ($null -ne $Connection -and -not $PSBoundParameters.ContainsKey('Connection')) {
            [void] $PSBoundParameters.Add('Connection', $Connection)
        }
        $Connection = PreProc -ParameterSetName $PSCmdlet.ParameterSetName @PSBoundParameters
        if ($null -eq $Connection) {
            break
        }
    }
    process {
        $device = [DSCDevice]::new()
        $PSBoundParameters.Keys.Where{
            $_ -in ($device | Get-Member -MemberType Property | Where-Object -FilterScript {$_.Name -ne 'Status'} ).Name
        }.ForEach{
            $device.$_ = $PSBoundParameters.$_
        }

        $existingDevice = Get-DSCPullServerAdminDevice -Connection $Connection -TargetName $device.TargetName
        if ($null -ne $existingDevice) {
            throw "A Device with TargetName '$TargetName' already exists."
        }

        switch ($Connection.Type) {
            ESE {
                if ($PSCmdlet.ShouldProcess($Connection.ESEFilePath)) {
                    try {
                        Mount-DSCPullServerESEDatabase -Connection $Connection -Mode None
                        Open-DSCPullServerTable -Connection $Connection -Table 'Devices'
                        Set-DSCPullServerESERecord -Connection $Connection -InputObject $device -Insert
                    } catch {
                        Write-Error -ErrorRecord $_ -ErrorAction Stop
                    } finally {
                        Dismount-DSCPullServerESEDatabase -Connection $Connection
                    }
                }
            }
            SQL {
                $tsqlScript = $device.GetSQLInsert()

                if ($PSCmdlet.ShouldProcess("$($Connection.SQLServer)\$($Connection.Database)", $tsqlScript)) {
                    Invoke-DSCPullServerSQLCommand -Connection $Connection -CommandType Set -Script $tsqlScript
                }
            }
            MDB {
                $tsqlScript = $device.GetMDBInsert()

                if ($PSCmdlet.ShouldProcess($Connection.MDBFilePath)) {
                    Invoke-DSCPullServerMDBCommand -Connection $Connection -CommandType Set -Script $tsqlScript
                }
            }
        }
    }
}
