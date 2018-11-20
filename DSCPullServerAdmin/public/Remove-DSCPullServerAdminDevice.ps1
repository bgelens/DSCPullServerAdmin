<#
    .SYNOPSIS
    Removes device entries (LCMv1) from a Pull Server Database.

    .DESCRIPTION
    LCMv1 (WMF4 / PowerShell 4.0) pull clients send information
    to the Pull Server which stores their data in the devices table.
    This function will remove devices from the devices table.

    .PARAMETER InputObject
    Pass in the device object to be removed from the database.

    .PARAMETER TargetName
    Define the TargetName of the device to be removed from the database.

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
    Remove-DSCPullServerAdminDevice -TargetName '192.168.0.1'

    .EXAMPLE
    Get-DSCPullServerAdminDevice -TargetName '192.168.0.1' | Remove-DSCPullServerAdminDevice
#>
function Remove-DSCPullServerAdminDevice {
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

        [Parameter(Mandatory, ParameterSetName = 'Manual_Connection')]
        [Parameter(Mandatory, ParameterSetName = 'Manual_SQL')]
        [Parameter(Mandatory, ParameterSetName = 'Manual_ESE')]
        [string] $TargetName,

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
        } else {
            $existingDevice = $InputObject
        }

        if ($null -eq $existingDevice) {
            Write-Warning -Message "A Device with TargetName '$TargetName' was not found"
        } else {
            switch ($Connection.Type) {
                ESE {
                    if ($PSCmdlet.ShouldProcess($Connection.ESEFilePath)) {
                        if ($PSCmdlet.MyInvocation.PipelinePosition -gt 1) {
                            Remove-DSCPullServerESERecord -Connection $Connection
                        } else {
                            Get-DSCPullServerAdminDevice -Connection $Connection -TargetName $existingDevice.TargetName |
                                Remove-DSCPullServerESERecord -Connection $Connection
                        }
                    }
                }
                SQL {
                    $tsqlScript = $existingDevice.GetSQLDelete()

                    if ($PSCmdlet.ShouldProcess("$($Connection.SQLServer)\$($Connection.Database)", $tsqlScript)) {
                        Invoke-DSCPullServerSQLCommand -Connection $Connection -CommandType Set -Script $tsqlScript
                    }
                }
            }
        }
    }
}
