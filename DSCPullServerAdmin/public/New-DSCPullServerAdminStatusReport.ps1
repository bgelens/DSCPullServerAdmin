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
        [DSCPullServerSQLConnection] $Connection = (Get-DSCPullServerAdminConnection -OnlyShowActive -Type SQL),

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
        } else {
            $tsqlScript = $report.GetSQLInsert()
        }

        if ($PSCmdlet.ShouldProcess("$($Connection.SQLServer)\$($Connection.Database)", $tsqlScript)) {
            Invoke-DSCPullServerSQLCommand -Connection $Connection -CommandType Set -Script $tsqlScript
        }
    }
}
