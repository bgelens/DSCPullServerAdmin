function Copy-DSCPullServerAdminDataESEToSQL {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [DSCPullServerESEConnection] $ESEConnection,

        [Parameter(Mandatory)]
        [DSCPullServerSQLConnection] $SQLConnection,

        [Parameter()]
        [ValidateSet('Devices', 'RegistrationData', 'StatusReports')]
        [string[]] $ObjectsToMigrate = @('Devices', 'RegistrationData'),

        [Parameter()]
        [switch] $Force
    )

    switch ($ObjectsToMigrate) {
        Devices {
            $devices = Get-DSCPullServerAdminDevice -Connection $ESEConnection
            foreach ($d in $devices) {
                $sqlD = Get-DSCPullServerAdminDevice -Connection $SQLConnection -TargetName $d.TargetName
                if ($null -eq $sqlD) {
                    if ($PSCmdlet.ShouldProcess($d.TargetName, "Create new device on $($SQLConnection.SQLServer)\$($SQLConnection.Database)")) {
                        Invoke-DSCPullServerSQLCommand -Connection $SQLConnection -CommandType Set -Script ($d.GetSQLInsert())
                    }
                } else {
                    if ($PSCmdlet.ShouldProcess($d.TargetName, "Replace existing device on $($SQLConnection.SQLServer)\$($SQLConnection.Database)")) {
                        if ($Force) {
                            Invoke-DSCPullServerSQLCommand -Connection $SQLConnection -CommandType Set -Script ($sqlD.GetSQLDelete())
                            Invoke-DSCPullServerSQLCommand -Connection $SQLConnection -CommandType Set -Script ($d.GetSQLInsert())
                        } else {
                            Write-Warning -Message "Unable to replace device $($d.TargetName) as Force switch was not set"
                        }
                    }
                }
            }
        }
        RegistrationData {
            $registrations = Get-DSCPullServerAdminRegistration -Connection $ESEConnection
            foreach ($r in $registrations) {
                $sqlReg = Get-DSCPullServerAdminRegistration -Connection $SQLConnection -AgentId $r.AgentId
                if ($null -eq $sqlReg) {
                    if ($PSCmdlet.ShouldProcess($r.AgentId, "Create new Registration on $($SQLConnection.SQLServer)\$($SQLConnection.Database)")) {
                        Invoke-DSCPullServerSQLCommand -Connection $SQLConnection -CommandType Set -Script ($r.GetSQLInsert())
                    }
                } else {
                    if ($PSCmdlet.ShouldProcess($r.AgentId, "Replace existing Registration on $($SQLConnection.SQLServer)\$($SQLConnection.Database)")) {
                        if ($Force) {
                            Invoke-DSCPullServerSQLCommand -Connection $SQLConnection -CommandType Set -Script ($sqlReg.GetSQLDelete())
                            Invoke-DSCPullServerSQLCommand -Connection $SQLConnection -CommandType Set -Script ($r.GetSQLInsert())
                        } else {
                            Write-Warning -Message "Unable to replace Registration $($r.AgentId) as Force switch was not set"
                        }
                    }
                }
            }
        }
        StatusReports {
            $reports = Get-DSCPullServerAdminStatusReport -Connection $ESEConnection
            foreach ($r in $reports) {
                $sqlRep = Get-DSCPullServerAdminStatusReport -Connection $SQLConnection -JobId $r.JobId -AgentId $r.Id
                if ($null -eq $sqlRep) {
                    if ($PSCmdlet.ShouldProcess($r.JobId, "Create new StatusReport on $($SQLConnection.SQLServer)\$($SQLConnection.Database)")) {
                        Invoke-DSCPullServerSQLCommand -Connection $SQLConnection -CommandType Set -Script ($r.GetSQLInsert())
                    }
                } else {
                    if ($PSCmdlet.ShouldProcess($r.JobId, "Replace StatusReport Registration on $($SQLConnection.SQLServer)\$($SQLConnection.Database)")) {
                        if ($Force) {
                            Invoke-DSCPullServerSQLCommand -Connection $SQLConnection -CommandType Set -Script ($sqlRep.GetSQLDelete())
                            Invoke-DSCPullServerSQLCommand -Connection $SQLConnection -CommandType Set -Script ($r.GetSQLInsert())
                        } else {
                            Write-Warning -Message "Unable to replace StatusReport $($r.JobId) as Force switch was not set"
                        }
                    }
                }
            }
        }
    }
}
