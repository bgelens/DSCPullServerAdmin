function Get-DSCPullServerAdminDevice {
    [OutputType([DSCDevice])]
    [CmdletBinding(DefaultParameterSetName = 'Connection')]
    param (
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [String] $TargetName,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [guid] $ConfigurationID,
        
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
                if ($PSBoundParameters.ContainsKey('TargetName')) {
                    $eseParams.Add('TargetName', $TargetName)
                }
                if ($PSBoundParameters.ContainsKey('ConfigurationID')) {
                    $eseParams.Add('ConfigurationID', $ConfigurationID)
                }

                Get-DSCPullServerESEDevice @eseParams
            }
            SQL {
                $tsqlScript = 'SELECT * FROM Devices'
                $filters = [System.Collections.ArrayList]::new()
                if ($PSBoundParameters.ContainsKey("TargetName")) {
                    [void] $filters.Add(("TargetName like '{0}'" -f $TargetName.Replace('*', '%')))
                }
                if ($PSBoundParameters.ContainsKey("ConfigurationID")) {
                    [void] $filters.Add(("ConfigurationID = '{0}'" -f $ConfigurationID))
                }

                if ($filters.Count -ge 1) {
                    $tsqlScript += " WHERE {0}" -f ($filters -join ' AND ')
                }

                Invoke-DSCPullServerSQLCommand -Connection $Connection -Script $tsqlScript | ForEach-Object {
                    try {
                        [DSCDevice]::New($_)
                    } catch {
                        Write-Error -ErrorRecord $_ -ErrorAction Continue
                    }
                }
            }
        }
    }
}
