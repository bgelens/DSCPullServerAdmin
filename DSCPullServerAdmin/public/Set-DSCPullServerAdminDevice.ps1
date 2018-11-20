<#
    .SYNOPSIS
    Overwrites device entry (LCMv1) properties in a Pull Server Database.

    .DESCRIPTION
    LCMv1 (WMF4 / PowerShell 4.0) pull clients send information
    to the Pull Server which stores their data in the devices table.
    This function will allow for manual overwrites of device properties
    in the devices table.

    .PARAMETER InputObject
    Pass in the device object to be modified from the database.

    .PARAMETER ConfigurationID
    Set the ConfigurationID property for the existing device.

    .PARAMETER TargetName
    Modify properties for the device with specified TargetName.

    .PARAMETER ServerCheckSum
    Set the ServerCheckSum property for the existing device.

    .PARAMETER TargetCheckSum
    Set the TargetCheckSum property for the existing device.

    .PARAMETER NodeCompliant
    Set the NodeCompliant property for the existing device.

    .PARAMETER LastComplianceTime
    Set the LastComplianceTime property for the existing device.

    .PARAMETER LastHeartbeatTime
    Set the LastHeartbeatTime property for the existing device.

    .PARAMETER Dirty
    Set the Dirty property for the existing device.

    .PARAMETER StatusCode
    Set the StatusCode property for the existing device.

    .PARAMETER Connection
    Accepts a specific Connection to be passed to target a specific database.
    When not specified, the currently Active Connection from memory will be used
    unless one off the parameters for ad-hoc connections (ESEFilePath, SQLServer)
    is used in which case, an ad-hoc connection is created.

    .PARAMETER ESEFilePath
    Define the EDB file path to use an ad-hoc ESE connection.

    .PARAMETER SQLServer
    Define the SQL Instance to use in an ad-hoc SQL connection.

    .PARAMETER Credential
    Define the Credentials to use with an ad-hoc SQL connection.

    .PARAMETER Database
    Define the database to use with an ad-hoc SQL connection.

    .EXAMPLE
    Set-DSCPullServerAdminDevice -TargetName '192.168.0.1' -ConfigurationID '80ee20f9-78df-480d-8175-9dd6cb09607a'

    .EXAMPLE
    Get-DSCPullServerAdminDevice -TargetName '192.168.0.1' | Set-DSCPullServerAdminDevice -ConfigurationID '80ee20f9-78df-480d-8175-9dd6cb09607a'
#>
function Set-DSCPullServerAdminDevice {
    [CmdletBinding(
        DefaultParameterSetName = 'InputObject_Connection',
        ConfirmImpact = 'High',
        SupportsShouldProcess
    )]
    param (
        [Parameter(Mandatory, ValueFromPipeline, ParameterSetName = 'InputObject_Connection')]
        [Parameter(Mandatory, ValueFromPipeline, ParameterSetName = 'InputObject_SQL')]
        [Parameter(Mandatory, ValueFromPipeline, ParameterSetName = 'InputObject_ESE')]
        [DSCDevice] $InputObject,

        [Parameter()]
        [guid] $ConfigurationID,

        [Parameter(Mandatory, ParameterSetName = 'Manual_Connection')]
        [Parameter(Mandatory, ParameterSetName = 'Manual_SQL')]
        [Parameter(Mandatory, ParameterSetName = 'Manual_ESE')]
        [ValidateNotNullOrEmpty()]
        [string] $TargetName,

        [Parameter()]
        [string] $ServerCheckSum,

        [Parameter()]
        [string] $TargetCheckSum,

        [Parameter()]
        [bool] $NodeCompliant,

        [Parameter()]
        [datetime] $LastComplianceTime,

        [Parameter()]
        [datetime] $LastHeartbeatTime,

        [Parameter()]
        [bool] $Dirty,

        [Parameter()]
        [uint32] $StatusCode,

        [Parameter(ParameterSetName = 'InputObject_Connection')]
        [Parameter(ParameterSetName = 'Manual_Connection')]
        [DSCPullServerConnection] $Connection = (Get-DSCPullServerAdminConnection -OnlyShowActive),

        [Parameter(Mandatory, ParameterSetName = 'InputObject_ESE')]
        [Parameter(Mandatory, ParameterSetName = 'Manual_ESE')]
        [ValidateNotNullOrEmpty()]
        [string] $ESEFilePath,

        [Parameter(Mandatory, ParameterSetName = 'InputObject_SQL')]
        [Parameter(Mandatory, ParameterSetName = 'Manual_SQL')]
        [ValidateNotNullOrEmpty()]
        [Alias('SQLInstance')]
        [string] $SQLServer,

        [Parameter(ParameterSetName = 'InputObject_SQL')]
        [Parameter(ParameterSetName = 'Manual_SQL')]
        [pscredential] $Credential,

        [Parameter(ParameterSetName = 'InputObject_SQL')]
        [Parameter(ParameterSetName = 'Manual_SQL')]
        [string] $Database
    )
    begin {
        if ($null -ne $Connection -and -not $PSBoundParameters.ContainsKey('Connection') -and $null -eq $script:GetConnection) {
            [void] $PSBoundParameters.Add('Connection', $Connection)
        } elseif ($null -ne $script:GetConnection -and -not $PSBoundParameters.ContainsKey('Connection')) {
            [void] $PSBoundParameters.Add('Connection', $script:GetConnection)
        } elseif ($null -ne $script:GetConnection) {
            $PSBoundParameters.Connection = $script:GetConnection
        }
        $Connection = PreProc -ParameterSetName $PSCmdlet.ParameterSetName @PSBoundParameters
        if ($null -eq $Connection) {
            break
        }
    }
    process {
        if (-not $PSBoundParameters.ContainsKey('InputObject')) {
            $existingDevice = Get-DSCPullServerAdminDevice -Connection $Connection -TargetName $TargetName
            if ($null -eq $existingDevice) {
                throw "A Device with TargetName '$TargetName' was not found"
            }
        } else {
            $existingDevice = $InputObject
        }

        $PSBoundParameters.Keys.Where{
            $_ -in ($existingDevice | Get-Member -MemberType Property | Where-Object -FilterScript {$_.Name -ne 'Status'} ).Name
        }.ForEach{
            if ($null -ne $PSBoundParameters.$_) {
                $existingDevice.$_ = $PSBoundParameters.$_
            }
        }

        switch ($Connection.Type) {
            ESE {
                if ($PSCmdlet.ShouldProcess($Connection.ESEFilePath)) {
                    if ($PSCmdlet.MyInvocation.PipelinePosition -gt 1) {
                        Set-DSCPullServerESERecord -Connection $Connection -InputObject $existingDevice
                    } else {
                        Get-DSCPullServerAdminDevice -Connection $Connection -TargetName $existingDevice.TargetName |
                            Set-DSCPullServerESERecord -Connection $Connection -InputObject $existingDevice
                    }
                }
            }
            SQL {
                $tsqlScript = $existingDevice.GetSQLUpdate()

                if ($PSCmdlet.ShouldProcess("$($Connection.SQLServer)\$($Connection.Database)", $tsqlScript)) {
                    Invoke-DSCPullServerSQLCommand -Connection $Connection -CommandType Set -Script $tsqlScript
                }
            }
        }
    }
}
