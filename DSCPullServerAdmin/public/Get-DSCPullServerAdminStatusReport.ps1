function Get-DSCPullServerAdminStatusReport {
    [OutputType([DSCNodeStatusReport])]
    [CmdletBinding(DefaultParameterSetName = 'Connection')]
    param (
        [Parameter()]
        [guid] $AgentId,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [Alias('Name')]
        [string] $NodeName,

        [Parameter()]
        [guid] $JobId,

        [Parameter()]
        [datetime] $FromStartTime,

        [Parameter()]
        [datetime] $ToStartTime,

        [Parameter(ParameterSetName = 'Connection')]
        [DSCPullServerConnection] $Connection = (Get-DSCPullServerAdminConnection -OnlyShowActive),

        [Parameter(Mandatory, ParameterSetName = 'ESE')]
        [ValidateNotNullOrEmpty()]
        [string] $ESEFilePath,

        [Parameter(Mandatory, ParameterSetName = 'SQL')]
        [ValidateNotNullOrEmpty()]
        [Alias('SQLInstance')]
        [string] $SQLServer,

        [Parameter(ParameterSetName = 'SQL')]
        [pscredential] $Credential,

        [Parameter(ParameterSetName = 'SQL')]
        [ValidateNotNullOrEmpty()]
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
        switch ($Connection.Type) {
            ESE {
                $eseParams = @{
                    Connection = $Connection
                }
                if ($PSBoundParameters.ContainsKey('AgentId')) {
                    $eseParams.Add('AgentId', $AgentId)
                }
                if ($PSBoundParameters.ContainsKey('NodeName')) {
                    $eseParams.Add('NodeName', $NodeName)
                }
                if ($PSBoundParameters.ContainsKey('FromStartTime')) {
                    $eseParams.Add('FromStartTime', $FromStartTime)
                }
                if ($PSBoundParameters.ContainsKey('ToStartTime')) {
                    $eseParams.Add('ToStartTime', $ToStartTime)
                }
                if ($PSBoundParameters.ContainsKey('JobId')) {
                    $eseParams.Add('JobId', $JobId)
                }

                Get-DSCPullServerESEStatusReport @eseParams
            }
            SQL {
                $tsqlScript = "SELECT * FROM StatusReport"
                $filters = [System.Collections.ArrayList]::new()
                if ($PSBoundParameters.ContainsKey('AgentId')) {
                    [void] $filters.Add(("Id = '{0}'" -f $AgentId))
                }
                if ($PSBoundParameters.ContainsKey("NodeName")) {
                    [void] $filters.Add(("NodeName like '{0}'" -f $NodeName.Replace('*', '%')))
                }
                if ($PSBoundParameters.ContainsKey("FromStartTime")) {
                    [void] $filters.Add(("StartTime >= '{0}'" -f (Get-Date $FromStartTime -f s)))
                }
                if ($PSBoundParameters.ContainsKey("ToStartTime")) {
                    [void] $filters.Add(("StartTime <= '{0}'" -f (Get-Date $ToStartTime -f s)))
                }
                if ($PSBoundParameters.ContainsKey("JobId")) {
                    [void] $filters.Add(("JobId = '{0}'" -f $JobId))
                }

                if ($filters.Count -ge 1) {
                    $tsqlScript += " WHERE {0}" -f ($filters -join ' AND ')
                }

                Invoke-DSCPullServerSQLCommand -Connection $Connection -Script $tsqlScript | ForEach-Object {
                    try {
                        [DSCNodeStatusReport]::New($_)
                    } catch {
                        Write-Error -ErrorRecord $_ -ErrorAction Continue
                    }
                }
            }
        }
    }
}
