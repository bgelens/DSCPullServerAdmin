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
        } else {
            $tsqlScript = $nodeRegistration.GetSQLInsert()
        }

        if ($PSCmdlet.ShouldProcess("$($Connection.SQLServer)\$($Connection.Database)", $tsqlScript)) {
            Invoke-DSCPullServerSQLCommand -Connection $Connection -CommandType Set -Script $tsqlScript
        }
    }
}
