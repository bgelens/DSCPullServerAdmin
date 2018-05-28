function Set-DSCPullServerAdminDevice {
    [CmdletBinding(
        DefaultParameterSetName = 'InputObject_Connection',
        ConfirmImpact = 'Medium',
        SupportsShouldProcess
    )]
    param (
        [Parameter(Mandatory, ValueFromPipeline, ParameterSetName = 'InputObject_Connection')]
        [Parameter(Mandatory, ValueFromPipeline, ParameterSetName = 'InputObject_SQL')]
        [DSCDevice] $InputObject,

        [Parameter(Mandatory, ParameterSetName = 'Manual_Connection')]
        [Parameter(Mandatory, ParameterSetName = 'Manual_SQL')]
        [guid] $ConfigurationID,

        [Parameter(Mandatory, ParameterSetName = 'Manual_Connection')]
        [Parameter(Mandatory, ParameterSetName = 'Manual_SQL')]
        [ValidateNotNullOrEmpty()]
        [string] $TargetName,

        [Parameter()]
        [string] $ServerCheckSum,

        [Parameter()]
        [string] $TargetCheckSum,

        [Parameter()]
        [bool] $NodeCompliant,

        [Parameter()]
        [datetime] $LastComplianceTime,

        [Parameter()]
        [datetime] $LastHeartbeatTime,

        [Parameter()]
        [bool] $Dirty,

        [Parameter()]
        [uint32] $StatusCode,

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
            $existingDevice = Get-DSCPullServerAdminDevice -Connection $Connection -TargetName $TargetName
        } else {
            $existingDevice = $InputObject
        }

        if ($null -eq $existingDevice) {
            throw "A Device with TargetName '$TargetName' was not found"
        } else {
            $PSBoundParameters.Keys.Where{
                $_ -in ($existingDevice | Get-Member -MemberType Property | Where-Object -FilterScript {$_.Name -ne 'Status'} ).Name
            }.ForEach{
                if ($null -ne $PSBoundParameters.$_) {
                    $existingDevice.$_ = $PSBoundParameters.$_
                }
            }
            $tsqlScript = $existingDevice.GetSQLUpdate()

            if ($PSCmdlet.ShouldProcess("$($Connection.SQLServer)\$($Connection.Database)", $tsqlScript)) {
                Invoke-DSCPullServerSQLCommand -Connection $Connection -CommandType Set -Script $tsqlScript
            }
        }
    }
}
