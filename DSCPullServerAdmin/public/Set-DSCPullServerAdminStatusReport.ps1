<#
    .SYNOPSIS
    Overwrites status report entries (LCMv2) in a Pull Server Database.

    .DESCRIPTION
    LCMv2 (WMF5+ / PowerShell 5+) pull clients send reports
    to the Pull Server which stores their data in the StatusReport table.
    This function will allow for manual Overwrites of status report properties
    in the StatusReport table.

    .PARAMETER InputObject
    Pass in the statusreport object to be modified from the database.

    .PARAMETER JobId
    Modify properties for the statusreport with specified JobId.

    .PARAMETER Id
    Set the Id property for the existing device.

    .PARAMETER OperationType
    Set the OperationType property for the existing device.

    .PARAMETER RefreshMode
    Set the RefreshMode property for the existing device.

    .PARAMETER Status
    Set the Status property for the existing device.

    .PARAMETER LCMVersion
    Set the LCMVersion property for the existing device.

    .PARAMETER ReportFormatVersion
    Set the ReportFormatVersion property for the existing device.

    .PARAMETER ConfigurationVersion
    Set the ConfigurationVersion property for the existing device.

    .PARAMETER NodeName
    Set the NodeName property for the existing device.

    .PARAMETER IPAddress
    Set the IPAddress property for the existing device.

    .PARAMETER StartTime
    Set the StartTime property for the existing device.

    .PARAMETER EndTime
    Set the EndTime property for the existing device.

    .PARAMETER LastModifiedTime
    Set the LastModifiedTime property for the existing device.

    .PARAMETER Errors
    Set the Errors property for the existing device.

    .PARAMETER StatusData
    Set the StatusData property for the existing device.

    .PARAMETER RebootRequested
    Set the RebootRequested property for the existing device.

    .PARAMETER AdditionalData
    Set the AdditionalData property for the existing device.

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
    Set-DSCPullServerAdminStatusReport -JobId '80ee20f9-78df-480d-8175-9dd6cb09607a' -NodeName 'lcmclient01'

    .EXAMPLE
    Get-DSCPullServerAdminStatusReport -JobId '80ee20f9-78df-480d-8175-9dd6cb09607a' | Set-DSCPullServerAdminStatusReport -NodeName 'lcmclient01'
#>
function Set-DSCPullServerAdminStatusReport {
    [CmdletBinding(
        DefaultParameterSetName = 'InputObject_Connection',
        ConfirmImpact = 'High',
        SupportsShouldProcess
    )]
    param (
        [Parameter(Mandatory, ValueFromPipeline, ParameterSetName = 'InputObject_Connection')]
        [Parameter(Mandatory, ValueFromPipeline, ParameterSetName = 'InputObject_SQL')]
        [Parameter(Mandatory, ValueFromPipeline, ParameterSetName = 'InputObject_ESE')]
        [DSCNodeStatusReport] $InputObject,

        [Parameter(Mandatory, ParameterSetName = 'Manual_Connection')]
        [Parameter(Mandatory, ParameterSetName = 'Manual_SQL')]
        [Parameter(Mandatory, ParameterSetName = 'Manual_ESE')]
        [guid] $JobId,

        [Parameter()]
        [Guid] $Id,

        [Parameter()]
        [string] $OperationType,

        [Parameter()]
        [string] $RefreshMode,

        [Parameter()]
        [string] $Status,

        [Parameter()]
        [string] $LCMVersion,

        [Parameter()]
        [string] $ReportFormatVersion,

        [Parameter()]
        [string] $ConfigurationVersion,

        [Parameter()]
        [string] $NodeName,

        [Parameter()]
        [IPAddress[]] $IPAddress,

        [Parameter()]
        [datetime] $StartTime,

        [Parameter()]
        [datetime] $EndTime,

        [Parameter()]
        [datetime] $LastModifiedTime,

        [Parameter()]
        [PSObject[]] $Errors,

        [Parameter()]
        [PSObject[]] $StatusData,

        [Parameter()]
        [bool] $RebootRequested,

        [Parameter()]
        [PSObject[]] $AdditionalData,

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
        } elseif ($null -ne $script:GetConnection) {
            [void] $PSBoundParameters.Add('Connection', $script:GetConnection)
        }
        $Connection = PreProc -ParameterSetName $PSCmdlet.ParameterSetName @PSBoundParameters
        if ($null -eq $Connection) {
            break
        }
    }
    process {
        if (-not $PSBoundParameters.ContainsKey('InputObject')) {
            $existingReport = Get-DSCPullServerAdminStatusReport -Connection $Connection -JobId $JobId
            if ($null -eq $existingReport) {
                throw "A Report with JobId '$JobId' was not found"
            }
        } else {
            $existingReport = $InputObject
        }

        $PSBoundParameters.Keys.Where{
            $_ -in ($existingReport | Get-Member -MemberType Property).Name
        }.ForEach{
            if ($null -ne $PSBoundParameters.$_) {
                $existingReport.$_ = $PSBoundParameters.$_
            }
        }

        switch ($Connection.Type) {
            ESE {
                if ($PSCmdlet.ShouldProcess($Connection.ESEFilePath)) {
                    if ($PSCmdlet.MyInvocation.PipelinePosition -gt 1) {
                        Set-DSCPullServerESERecord -Connection $Connection -InputObject $existingReport
                    } else {
                        Get-DSCPullServerAdminStatusReport -Connection $Connection -JobId $existingReport.JobId |
                            Set-DSCPullServerESERecord -Connection $Connection -InputObject $existingReport
                    }
                }
            }
            SQL {
                $tsqlScript = $existingReport.GetSQLUpdate()

                if ($PSCmdlet.ShouldProcess("$($Connection.SQLServer)\$($Connection.Database)", $tsqlScript)) {
                    Invoke-DSCPullServerSQLCommand -Connection $Connection -CommandType Set -Script $tsqlScript
                }
            }
        }
    }
}
