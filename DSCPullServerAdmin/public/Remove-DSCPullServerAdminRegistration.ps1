<#
    .SYNOPSIS
    Removes node registration entries (LCMv2) from a Pull Server Database.

    .DESCRIPTION
    LCMv2 (WMF5+ / PowerShell 5+) pull clients send information
    to the Pull Server which stores their data in the registrationdata table.
    This function will remove node registrations from the registrationdata table.

    .PARAMETER InputObject
    Pass in the registration object to be removed from the database.

    .PARAMETER AgentId
    Define the AgentId of the registration to be removed from the database.

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
    Remove-DSCPullServerAdminRegistration -AgentId '80ee20f9-78df-480d-8175-9dd6cb09607a'

    .EXAMPLE
    Get-DSCPullServerAdminRegistration -TargetName '80ee20f9-78df-480d-8175-9dd6cb09607a' | Remove-DSCPullServerAdminRegistration
#>
function Remove-DSCPullServerAdminRegistration {
    [CmdletBinding(
        DefaultParameterSetName = 'InputObject_Connection',
        ConfirmImpact = 'High',
        SupportsShouldProcess
    )]
    param (
        [Parameter(Mandatory, ValueFromPipeline, ParameterSetName = 'InputObject_Connection')]
        [Parameter(Mandatory, ValueFromPipeline, ParameterSetName = 'InputObject_SQL')]
        [Parameter(Mandatory, ValueFromPipeline, ParameterSetName = 'InputObject_ESE')]
        [Parameter(Mandatory, ValueFromPipeline, ParameterSetName = 'InputObject_MDB')]
        [DSCNodeRegistration] $InputObject,

        [Parameter(Mandatory, ParameterSetName = 'Manual_Connection')]
        [Parameter(Mandatory, ParameterSetName = 'Manual_SQL')]
        [Parameter(Mandatory, ParameterSetName = 'Manual_ESE')]
        [Parameter(Mandatory, ParameterSetName = 'Manual_MDB')]
        [guid] $AgentId,

        [Parameter(ParameterSetName = 'InputObject_Connection')]
        [Parameter(ParameterSetName = 'Manual_Connection')]
        [DSCPullServerConnection] $Connection = (Get-DSCPullServerAdminConnection -OnlyShowActive),

        [Parameter(Mandatory, ParameterSetName = 'InputObject_ESE')]
        [Parameter(Mandatory, ParameterSetName = 'Manual_ESE')]
        [ValidateScript({$_ | Assert-DSCPullServerDatabaseFilePath -Type 'ESE'})]
        [System.IO.FileInfo] $ESEFilePath,

        [Parameter(Mandatory, ParameterSetName = 'InputObject_MDB')]
        [Parameter(Mandatory, ParameterSetName = 'Manual_MDB')]
        [ValidateScript({$_ | Assert-DSCPullServerDatabaseFilePath -Type 'MDB'})]
        [System.IO.FileInfo] $MDBFilePath,

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
            $existingRegistration = Get-DSCPullServerAdminRegistration -Connection $Connection -AgentId $AgentId
        } else {
            $existingRegistration = $InputObject
        }

        if ($null -eq $existingRegistration) {
            Write-Warning -Message "A NodeRegistration with AgentId '$AgentId' was not found"
        } else {
            switch ($Connection.Type) {
                ESE {
                    if ($PSCmdlet.ShouldProcess($Connection.ESEFilePath)) {
                        if ($PSCmdlet.MyInvocation.PipelinePosition -gt 1) {
                            Remove-DSCPullServerESERecord -Connection $Connection
                        } else {
                            Get-DSCPullServerAdminRegistration -Connection $Connection -AgentId $existingRegistration.AgentId |
                                Remove-DSCPullServerESERecord -Connection $Connection
                        }
                    }
                }
                SQL {
                    $tsqlScript = $existingRegistration.GetSQLDelete()

                    if ($PSCmdlet.ShouldProcess("$($Connection.SQLServer)\$($Connection.Database)", $tsqlScript)) {
                        Invoke-DSCPullServerSQLCommand -Connection $Connection -CommandType Set -Script $tsqlScript
                    }
                }
                MDB {
                    $tsqlScript = $existingRegistration.GetMDBDelete()

                    if ($PSCmdlet.ShouldProcess($Connection.MDBFilePath)) {
                        Invoke-DSCPullServerMDBCommand -Connection $Connection -CommandType Set -Script $tsqlScript
                    }
                }
            }
        }
    }
}
