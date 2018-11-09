<#
    .SYNOPSIS
    Creates status report entries (LCMv2) in a Pull Server Database.

    .DESCRIPTION
    LCMv2 (WMF5+ / PowerShell 5+) pull clients send reports
    to the Pull Server which stores their data in the StatusReport table.
    This function will allow for manual creation of status reports
    in the StatusReport table and allows for multiple properties to be set.

    .PARAMETER JobId
    Set the JobId property for the new device.

    .PARAMETER Id
    Set the Id property for the new device.

    .PARAMETER OperationType
    Set the OperationType property for the new device.

    .PARAMETER RefreshMode
    Set the RefreshMode property for the new device.

    .PARAMETER Status
    Set the Status property for the new device.

    .PARAMETER LCMVersion
    Set the LCMVersion property for the new device.

    .PARAMETER ReportFormatVersion
    Set the ReportFormatVersion property for the new device.

    .PARAMETER ConfigurationVersion
    Set the ConfigurationVersion property for the new device.

    .PARAMETER NodeName
    Set the NodeName property for the new device.

    .PARAMETER IPAddress
    Set the IPAddress property for the new device.

    .PARAMETER StartTime
    Set the StartTime property for the new device.

    .PARAMETER EndTime
    Set the EndTime property for the new device.

    .PARAMETER LastModifiedTime
    Set the LastModifiedTime property for the new device.

    .PARAMETER Errors
    Set the Errors property for the new device.

    .PARAMETER StatusData
    Set the StatusData property for the new device.

    .PARAMETER RebootRequested
    Set the RebootRequested property for the new device.

    .PARAMETER AdditionalData
    Set the AdditionalData property for the new device.

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
    New-DSCPullServerAdminStatusReport -JobId '80ee20f9-78df-480d-8175-9dd6cb09607a' -NodeName 'lcmclient01'
#>
function New-DSCPullServerAdminStatusReport {
    [CmdletBinding(
        DefaultParameterSetName = 'Connection',
        ConfirmImpact = 'Medium',
        SupportsShouldProcess
    )]
    param (
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [guid] $JobId,

        [Parameter()]
        [Guid] $Id = [guid]::NewGuid(),

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

        [Parameter(ParameterSetName = 'Connection')]
        [DSCPullServerConnection] $Connection = (Get-DSCPullServerAdminConnection -OnlyShowActive),

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
        $report = [DSCNodeStatusReport]::new()
        $PSBoundParameters.Keys.Where{
            $_ -in ($report | Get-Member -MemberType Property).Name
        }.ForEach{
            $report.$_ = $PSBoundParameters.$_
        }

        $existingReport = Get-DSCPullServerAdminStatusReport -Connection $Connection -JobId $report.JobId
        if ($null -ne $existingReport) {
            throw "A Report with JobId '$JobId' already exists."
        }

        switch ($Connection.Type) {
            ESE {
                if ($PSCmdlet.ShouldProcess($Connection.ESEFilePath)) {
                    try {
                        Mount-DSCPullServerESEDatabase -Connection $Connection -Mode None
                        Open-DSCPullServerTable -Connection $Connection -Table 'StatusReport'
                        Set-DSCPullServerESERecord -Connection $Connection -InputObject $report -Insert
                    } catch {
                        Write-Error -ErrorRecord $_ -ErrorAction Stop
                    } finally {
                        Dismount-DSCPullServerESEDatabase -Connection $Connection
                    }
                }
            }
            SQL {
                $tsqlScript = $report.GetSQLInsert()

                if ($PSCmdlet.ShouldProcess("$($Connection.SQLServer)\$($Connection.Database)", $tsqlScript)) {
                    Invoke-DSCPullServerSQLCommand -Connection $Connection -CommandType Set -Script $tsqlScript
                }
            }
        }
    }
}
