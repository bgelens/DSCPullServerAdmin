<#
    .SYNOPSIS
    Removes status report entries (LCMv2) from a Pull Server Database.

    .DESCRIPTION
    LCMv2 (WMF5+ / PowerShell 5+) pull clients send reports
    to the Pull Server which stores their data in the StatusReport table.
    This function will remove status reports from the StatusReport table.

    .PARAMETER InputObject
    Pass in the status report object to be removed from the database.

    .PARAMETER JobId
    Define the JobId of the status report to be removed from the database.

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
    Remove-DSCPullServerAdminStatusReport -JobId '80ee20f9-78df-480d-8175-9dd6cb09607a'

    .EXAMPLE
    Get-DSCPullServerAdminStatusReport -JobId '80ee20f9-78df-480d-8175-9dd6cb09607a' | Remove-DSCPullServerAdminStatusReport
#>
function Remove-DSCPullServerAdminStatusReport {
    [CmdletBinding(
        DefaultParameterSetName = 'InputObject_Connection',
        ConfirmImpact = 'High',
        SupportsShouldProcess
    )]
    param (
        [Parameter(Mandatory, ValueFromPipeline, ParameterSetName = 'InputObject_Connection')]
        [Parameter(Mandatory, ValueFromPipeline, ParameterSetName = 'InputObject_SQL')]
        [DSCNodeStatusReport] $InputObject,

        [Parameter(Mandatory, ParameterSetName = 'Manual_Connection')]
        [Parameter(Mandatory, ParameterSetName = 'Manual_SQL')]
        [guid] $JobId,

        [Parameter(ParameterSetName = 'InputObject_Connection')]
        [Parameter(ParameterSetName = 'Manual_Connection')]
        [DSCPullServerConnection] $Connection = (Get-DSCPullServerAdminConnection -OnlyShowActive),

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
            Write-Warning -Message "A Report with JobId '$JobId' was not found"
        } else {
            switch ($Connection.Type) {
                ESE {
                    if ($PSCmdlet.ShouldProcess($Connection.ESEFilePath)) {
                        if ($PSCmdlet.MyInvocation.PipelinePosition -gt 1) {
                            Remove-DSCPullServerESERecord -Connection $Connection
                        } else {
                            Get-DSCPullServerESEStatusReport -Connection $Connection -JobId $existingReport.JobId |
                                Remove-DSCPullServerESERecord -Connection $Connection
                        }
                    }
                }
                SQL {
                    $tsqlScript = $existingReport.GetSQLDelete()
    
                    if ($PSCmdlet.ShouldProcess("$($Connection.SQLServer)\$($Connection.Database)", $tsqlScript)) {
                        Invoke-DSCPullServerSQLCommand -Connection $Connection -CommandType Set -Script $tsqlScript
                    }
                }
            }
        }
    }
}
