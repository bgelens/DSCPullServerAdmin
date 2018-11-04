function Get-DSCPullServerESEDevice {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [DSCPullServerESEConnection] $Connection,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [Alias('Name')]
        [string] $TargetName,

        [Parameter()]
        [guid] $ConfigurationID
    )
    begin {
        $table = 'Devices'

        $stringColumns = @(
            'TargetName',
            'ServerCheckSum',
            'TargetChecksum'
        )

        $boolColumns = @(
            'NodeCompliant',
            'Dirty'
        )

        $datetimeColumns = @(
            'LastComplianceTime',
            'LastHeartbeatTime'
        )

        [Microsoft.Isam.Esent.Interop.JET_TABLEID] $tableId = [Microsoft.Isam.Esent.Interop.JET_TABLEID]::Nil

        try {
            Mount-DSCPullServerESEDatabase -Connection $Connection -Mode None
            [void] [Microsoft.Isam.Esent.Interop.Api]::JetOpenTable(
                $Connection.SessionId,
                $Connection.DbId,
                $Table,
                $null,
                0,
                [Microsoft.Isam.Esent.Interop.OpenTableGrbit]::None,
                [ref]$tableId
            )
            $Connection.TableId = $tableId
        } catch {
            Write-Error -ErrorRecord $_ -ErrorAction Stop
        }
    }
    process {
        try {
            [Microsoft.Isam.Esent.Interop.Api]::MoveBeforeFirst($Connection.SessionId, $tableId)

            while ([Microsoft.Isam.Esent.Interop.Api]::TryMoveNext($Connection.SessionId, $tableId)) {
                foreach ($column in ([Microsoft.Isam.Esent.Interop.Api]::GetTableColumns($Connection.SessionId, $tableId))) {
                    $device = [DSCDevice]::new()
                    if ($column.Name -in $stringColumns) {
                        $device."$($column.Name)" = [Microsoft.Isam.Esent.Interop.Api]::RetrieveColumnAsString(
                            $Connection.SessionId,
                            $tableId,
                            $column.Columnid,
                            [System.Text.Encoding]::Unicode
                        )
                    } elseif ($column.Name -in $boolColumns) {
                        $row = [Microsoft.Isam.Esent.Interop.Api]::RetrieveColumnAsBoolean(
                            $Connection.SessionId,
                            $tableId,
                            $column.Columnid
                        )
                        if ($row.HasValue) {
                            $device."$($column.Name)" = $row.Value
                        }
                    } elseif ($column.Name -eq 'ConfigurationID') {
                        $device."$($column.Name)" = [Microsoft.Isam.Esent.Interop.Api]::RetrieveColumnAsGuid(
                            $Connection.SessionId,
                            $tableId,
                            $column.Columnid
                        )
                    } elseif ($column.Name -in $datetimeColumns) {
                        $row = [Microsoft.Isam.Esent.Interop.Api]::RetrieveColumnAsDateTime(
                            $Connection.SessionId,
                            $tableId,
                            $column.Columnid
                        )
                        if ($row.HasValue) {
                            $device."$($column.Name)" = $row.Value
                        }
                    } elseif ($column.Name -eq 'StatusCode') {
                        $row = [Microsoft.Isam.Esent.Interop.Api]::RetrieveColumnAsInt32(
                            $Connection.SessionId,
                            $tableId,
                            $column.Columnid
                        )
                        if ($row.HasValue) {
                            $device.StatusCode = $row.Value
                        }
                    } else {
                        $device."$($column.Name)" = [Microsoft.Isam.Esent.Interop.Api]::RetrieveColumnAsString(
                            $Connection.SessionId,
                            $tableId,
                            $column.Columnid,
                            [System.Text.Encoding]::Unicode
                        )
                    }
                }

                if ($PSBoundParameters.ContainsKey('TargetName') -and $device.TargetName -notlike $TargetName) {
                    continue
                }
                if ($PSBoundParameters.ContainsKey('ConfigurationID') -and $device.ConfigurationID -notlike $ConfigurationID) {
                    continue
                }

                $device
            }
        } catch {
            Write-Error -ErrorRecord $_ -ErrorAction Stop
        } 
    }
    end {
        Dismount-DSCPullServerESEDatabase -Connection $Connection
    }
}
