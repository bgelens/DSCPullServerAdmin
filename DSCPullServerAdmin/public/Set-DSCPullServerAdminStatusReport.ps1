function Set-DSCPullServerAdminStatusReport {
    [CmdletBinding(
        DefaultParameterSetName = 'InputObject_Connection',
        ConfirmImpact = 'Medium',
        SupportsShouldProcess
    )]
    param (
        [Parameter(Mandatory, ValueFromPipeline, ParameterSetName = 'InputObject_Connection')]
        [Parameter(Mandatory, ValueFromPipeline, ParameterSetName = 'InputObject_SQL')]
        [DSCNodeStatusReport] $InputObject,

        [Parameter(Mandatory, ParameterSetName = 'Manual_Connection')]
        [Parameter(Mandatory, ParameterSetName = 'Manual_SQL')]
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
        [DSCPullServerSQLConnection] $Connection = (Get-DSCPullServerAdminConnection -OnlyShowActive -Type SQL),

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
        if ($null -ne $Connection -and -not $PSBoundParameters.ContainsKey('Connection')) {
            [void] $PSBoundParameters.Add('Connection', $Connection)
        }
        $Connection = PreProc -ParameterSetName $PSCmdlet.ParameterSetName @PSBoundParameters
        if ($null -eq $Connection) {
            break
        }
    }
    process {
        if (-not $PSBoundParameters.ContainsKey('InputObject')) {
            $existingReport = Get-DSCPullServerAdminStatusReport -Connection $Connection -JobId $JobId
        } else {
            $existingReport = $InputObject
        }

        if ($null -eq $existingReport) {
            throw "A Report with JobId '$JobId' was not found"
        } else {
            $PSBoundParameters.Keys.Where{
                $_ -in ($existingReport | Get-Member -MemberType Property).Name
            }.ForEach{
                if ($null -ne $PSBoundParameters.$_) {
                    $existingReport.$_ = $PSBoundParameters.$_
                }
            }
            $tsqlScript = $existingReport.GetSQLUpdate()

            if ($PSCmdlet.ShouldProcess("$($Connection.SQLServer)\$($Connection.Database)", $tsqlScript)) {
                Invoke-DSCPullServerSQLCommand -Connection $Connection -CommandType Set -Script $tsqlScript
            }
        }
    }
}
