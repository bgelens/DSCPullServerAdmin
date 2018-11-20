<#
    .SYNOPSIS
    Copy data between 2 Database connections

    .DESCRIPTION
    This function allows for data to be copied over from
    a connection to another connection. This allows
    a user to migrate over data from an ESENT type Pull Server to
    a SQL type Pull Server, SQL to SQL type Pull Server, SQL to ESENT type
    Pull Server and ESENT to ESENT Type Pull Server without loosing data.

    .PARAMETER Connection1
    A specifically passed in Connection to migrate data out of.

    .PARAMETER Connection2
    A specifically passed in Connection to migrate data in to.

    .PARAMETER ObjectsToMigrate
    Define the object types to migrate. Defaults to Devices and RegistrationData.

    .PARAMETER Force
    When specified, existing records in the target database will be overwritten. When not specified
    existing data will not be overwritten and Warnings will be provided to inform
    the user.

    .EXAMPLE
    $eseConnection = New-DSCPullServerAdminConnection -ESEFilePath C:\EDB\Devices.edb
    $sqlConnection = New-DSCPullServerAdminConnection -SQLServer sqlserver\instance -Database dsc -Credential sa

    Copy-DSCPullServerAdminData -ObjectsToMigrate Devices, RegistrationData, StatusReports -Connection1 $eseConnection -Connection2 $sqlConnection -Force
#>
function Copy-DSCPullServerAdminData {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [DSCPullServerConnection] $Connection1,

        [Parameter(Mandatory)]
        [DSCPullServerConnection] $Connection2,

        [Parameter(Mandatory)]
        [ValidateSet('Devices', 'RegistrationData', 'StatusReports')]
        [string[]] $ObjectsToMigrate,

        [Parameter()]
        [switch] $Force
    )

    switch ($ObjectsToMigrate) {
        Devices {
            $devices = Get-DSCPullServerAdminDevice -Connection $Connection1
            foreach ($d in $devices) {
                $con2D = Get-DSCPullServerAdminDevice -Connection $Connection2 -TargetName $d.TargetName
                if ($null -eq $con2D) {
                    switch ($Connection2.Type) {
                        ESE {
                            if ($PSCmdlet.ShouldProcess($d.TargetName, "Create new device on $($Connection2.ESEFilePath)")) {
                                $d | New-DSCPullServerAdminDevice -Connection $Connection2 -Confirm:$false
                            }
                        }
                        SQL {
                            if ($PSCmdlet.ShouldProcess($d.TargetName, "Create new device on $($Connection2.SQLServer)\$($Connection2.Database)")) {
                                Invoke-DSCPullServerSQLCommand -Connection $Connection2 -CommandType Set -Script ($d.GetSQLInsert())
                            }
                        }
                    }
                } else {
                    switch ($Connection2.Type) {
                        ESE {
                            if ($PSCmdlet.ShouldProcess($d.TargetName, "Replace existing device on $($Connection2.ESEFilePath)")) {
                                if ($Force) {
                                    $d | Set-DSCPullServerAdminDevice -Connection $Connection2 -Confirm:$false
                                } else {
                                    Write-Warning -Message "Unable to replace device $($d.TargetName) as Force switch was not set"
                                }
                            }
                        }
                        SQL {
                            if ($PSCmdlet.ShouldProcess($d.TargetName, "Replace existing device on $($Connection2.SQLServer)\$($Connection2.Database)")) {
                                if ($Force) {
                                    Invoke-DSCPullServerSQLCommand -Connection $Connection2 -CommandType Set -Script ($con2D.GetSQLDelete())
                                    Invoke-DSCPullServerSQLCommand -Connection $Connection2 -CommandType Set -Script ($d.GetSQLInsert())
                                } else {
                                    Write-Warning -Message "Unable to replace device $($d.TargetName) as Force switch was not set"
                                }
                            }
                        }
                    }
                }
            }
        }
        RegistrationData {
            $registrations = Get-DSCPullServerAdminRegistration -Connection $Connection1
            foreach ($r in $registrations) {
                $con2Reg = Get-DSCPullServerAdminRegistration -Connection $Connection2 -AgentId $r.AgentId
                if ($null -eq $con2Reg) {
                    switch ($Connection2.Type) {
                        ESE {
                            if ($PSCmdlet.ShouldProcess($r.AgentId, "Create new Registration on $($Connection2.ESEFilePath)")) {
                                $r | New-DSCPullServerAdminRegistration -Connection $Connection2 -Confirm:$false
                            }
                        }
                        SQL {
                            if ($PSCmdlet.ShouldProcess($r.AgentId, "Create new Registration on $($Connection2.SQLServer)\$($Connection2.Database)")) {
                                Invoke-DSCPullServerSQLCommand -Connection $Connection2 -CommandType Set -Script ($r.GetSQLInsert())
                            }
                        }
                    }
                } else {
                    switch ($Connection2.Type) {
                        ESE {
                            if ($PSCmdlet.ShouldProcess($r.AgentId, "Replace existing Registration on $($Connection2.ESEFilePath)")) {
                                if ($Force) {
                                    $r | Set-DSCPullServerAdminRegistration -Connection $Connection2 -Confirm:$false
                                } else {
                                    Write-Warning -Message "Unable to replace Registration $($r.AgentId) as Force switch was not set"
                                }
                            }
                        }
                        SQL {
                            if ($PSCmdlet.ShouldProcess($r.AgentId, "Replace existing Registration on $($Connection2.SQLServer)\$($Connection2.Database)")) {
                                if ($Force) {
                                    Invoke-DSCPullServerSQLCommand -Connection $Connection2 -CommandType Set -Script ($con2Reg.GetSQLDelete())
                                    Invoke-DSCPullServerSQLCommand -Connection $Connection2 -CommandType Set -Script ($r.GetSQLInsert())
                                } else {
                                    Write-Warning -Message "Unable to replace Registration $($r.AgentId) as Force switch was not set"
                                }
                            }
                        }
                    }
                }
            }
        }
        StatusReports {
            $reports = Get-DSCPullServerAdminStatusReport -Connection $Connection1
            foreach ($r in $reports) {
                $con2Rep = Get-DSCPullServerAdminStatusReport -Connection $Connection2 -JobId $r.JobId
                if ($null -eq $con2Rep) {
                    switch ($Connection2.Type) {
                        ESE {
                            if ($PSCmdlet.ShouldProcess($r.JobId, "Create new StatusReport on $($Connection2.ESEFilePath)")) {
                                $r | New-DSCPullServerAdminStatusReport -Connection $Connection2 -Confirm:$false
                            }
                        }
                        SQL {
                            if ($PSCmdlet.ShouldProcess($r.JobId, "Create new StatusReport on $($Connection2.SQLServer)\$($Connection2.Database)")) {
                                Invoke-DSCPullServerSQLCommand -Connection $Connection2 -CommandType Set -Script ($r.GetSQLInsert())
                            }
                        }
                    }
                } else {
                    switch ($Connection2.Type) {
                        ESE {
                            if ($PSCmdlet.ShouldProcess($r.JobId, "Replace StatusReport Registration on $($Connection2.ESEFilePath)")) {
                                if ($Force) {
                                    $r | Set-DSCPullServerAdminStatusReport -Connection $Connection2 -Confirm:$false
                                } else {
                                    Write-Warning -Message "Unable to replace StatusReport $($r.JobId) as Force switch was not set"
                                }
                            }
                        }
                        SQL {
                            if ($PSCmdlet.ShouldProcess($r.JobId, "Replace StatusReport Registration on $($Connection2.SQLServer)\$($Connection2.Database)")) {
                                if ($Force) {
                                    Invoke-DSCPullServerSQLCommand -Connection $Connection2 -CommandType Set -Script ($con2Rep.GetSQLDelete())
                                    Invoke-DSCPullServerSQLCommand -Connection $Connection2 -CommandType Set -Script ($r.GetSQLInsert())
                                } else {
                                    Write-Warning -Message "Unable to replace StatusReport $($r.JobId) as Force switch was not set"
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
