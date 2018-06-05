function Set-DSCPullServerAdminRegistration {
    [CmdletBinding(
        DefaultParameterSetName = 'InputObject_Connection',
        ConfirmImpact = 'Medium',
        SupportsShouldProcess
    )]
    param (
        [Parameter(Mandatory, ValueFromPipeline, ParameterSetName = 'InputObject_Connection')]
        [Parameter(Mandatory, ValueFromPipeline, ParameterSetName = 'InputObject_SQL')]
        [DSCNodeRegistration] $InputObject,

        [Parameter(Mandatory, ParameterSetName = 'Manual_Connection')]
        [Parameter(Mandatory, ParameterSetName = 'Manual_SQL')]
        [guid] $AgentId,

        [Parameter()]
        [ValidateSet('2.0')]
        [string] $LCMVersion = '2.0',

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string] $NodeName,

        [Parameter()]
        [IPAddress[]] $IPAddress,

        [Parameter()]
        [string[]] $ConfigurationNames,

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
            $existingRegistration = Get-DSCPullServerAdminRegistration -Connection $Connection -AgentId $AgentId
            if ($null -eq $existingRegistration) {
                throw "A NodeRegistration with AgentId '$AgentId' was not found"
            }
        } else {
            $existingRegistration = $InputObject
        }

        $PSBoundParameters.Keys.Where{
            $_ -in ($existingRegistration | Get-Member -MemberType Property).Name
        }.ForEach{
            if ($null -ne $PSBoundParameters.$_) {
                $existingRegistration.$_ = $PSBoundParameters.$_
            }
        }

        $tsqlScript = $existingRegistration.GetSQLUpdate()

        if ($PSCmdlet.ShouldProcess("$($Connection.SQLServer)\$($Connection.Database)", $tsqlScript)) {
            Invoke-DSCPullServerSQLCommand -Connection $Connection -CommandType Set -Script $tsqlScript
        }
    }
}
