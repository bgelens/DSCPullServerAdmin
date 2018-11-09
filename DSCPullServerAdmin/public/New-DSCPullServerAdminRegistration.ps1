<#
    .SYNOPSIS
    Creates node registration entries (LCMv2) in a Pull Server Database.

    .DESCRIPTION
    LCMv2 (WMF5+ / PowerShell 5+) pull clients send information
    to the Pull Server which stores their data in the registrationdata table.
    This function will allow for manual creation of registrations in the
    registrationdata table and allows for multiple properties to be set.

    .PARAMETER AgentId
    Set the AgentId property for the new device.

    .PARAMETER LCMVersion
    Set the LCMVersion property for the new device.

    .PARAMETER NodeName
    Set the NodeName property for the new device.

    .PARAMETER IPAddress
    Set the IPAddress property for the new device.

    .PARAMETER ConfigurationNames
    Set the ConfigurationNames property for the new device.

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
    New-DSCPullServerAdminRegistration -AgentId '80ee20f9-78df-480d-8175-9dd6cb09607a' -NodeName 'lcmclient01'
#>
function New-DSCPullServerAdminRegistration {
    [CmdletBinding(
        DefaultParameterSetName = 'Connection',
        ConfirmImpact = 'Medium',
        SupportsShouldProcess
    )]
    param (
        [Parameter(Mandatory)]
        [guid] $AgentId,

        [Parameter()]
        [ValidateSet('2.0')]
        [string] $LCMVersion = '2.0',

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string] $NodeName,

        [Parameter()]
        [IPAddress[]] $IPAddress,

        [Parameter()]
        [string[]] $ConfigurationNames,

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
        if (-not $PSBoundParameters.ContainsKey('LCMVersion')) {
            $PSBoundParameters.Add('LCMVersion', $LCMVersion)
        }
    }
    process {
        $nodeRegistration = [DSCNodeRegistration]::new()
        $PSBoundParameters.Keys.Where{
            $_ -in ($nodeRegistration | Get-Member -MemberType Property).Name
        }.ForEach{
            $nodeRegistration.$_ = $PSBoundParameters.$_
        }

        $existingRegistration = Get-DSCPullServerAdminRegistration -Connection $Connection -AgentId $nodeRegistration.AgentId
        if ($null -ne $existingRegistration) {
            throw "A NodeRegistration with AgentId '$AgentId' already exists."
        }

        switch ($Connection.Type) {
            ESE {
                if ($PSCmdlet.ShouldProcess($Connection.ESEFilePath)) {
                    try {
                        Mount-DSCPullServerESEDatabase -Connection $Connection -Mode None
                        Open-DSCPullServerTable -Connection $Connection -Table 'RegistrationData'
                        Set-DSCPullServerESERecord -Connection $Connection -InputObject $nodeRegistration -Insert
                    } catch {
                        Write-Error -ErrorRecord $_ -ErrorAction Stop
                    } finally {
                        Dismount-DSCPullServerESEDatabase -Connection $Connection
                    }
                }
            }
            SQL {
                $tsqlScript = $nodeRegistration.GetSQLInsert()

                if ($PSCmdlet.ShouldProcess("$($Connection.SQLServer)\$($Connection.Database)", $tsqlScript)) {
                    Invoke-DSCPullServerSQLCommand -Connection $Connection -CommandType Set -Script $tsqlScript
                }
            }
        }
    }
}
