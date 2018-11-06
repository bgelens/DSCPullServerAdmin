function Get-DSCPullServerESEStatusReport {
    [Diagnostics.CodeAnalysis.SuppressMessage('PSAvoidUsingEmptyCatchBlock', '')]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [DSCPullServerESEConnection] $Connection,

        [Parameter()]
        [Alias('Id')]
        [guid] $AgentId,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [Alias('Name')]
        [string] $NodeName,

        [Parameter()]
        [datetime] $FromStartTime,

        [Parameter()]
        [datetime] $ToStartTime,

        [Parameter()]
        [guid] $JobId,

        [Parameter()]
        [ValidateSet('All', 'LocalConfigurationManager', 'Consistency', 'Initial')]
        [string] $OperationType = 'All'
    )
    begin {
        $table = 'StatusReport'

        $stringColumns = @(
            'NodeName',
            'OperationType',
            'RefreshMode',
            'Status',
            'LCMVersion',
            'ReportFormatVersion',
            'ConfigurationVersion',
            'RebootRequested'
        )

        $guidColumns = @(
            'JobId',
            'Id'
        )

        $datetimeColumns = @(
            'StartTime',
            'EndTime',
            'LastModifiedTime'
        )

        $deserializeColumns = @(
            'Errors',
            'StatusData'
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
                $statusReport = [DSCNodeStatusReport]::new()
                foreach ($column in ([Microsoft.Isam.Esent.Interop.Api]::GetTableColumns($Connection.SessionId, $tableId))) {
                    if ($column.Name -in $datetimeColumns) {
                        $statusReport."$($column.Name)" = [Microsoft.Isam.Esent.Interop.Api]::RetrieveColumnAsDateTime(
                            $Connection.SessionId,
                            $tableId,
                            $column.Columnid
                        )
                    } elseif ($column.Name -eq 'IPAddress') {
                        $ipAddress = ([Microsoft.Isam.Esent.Interop.Api]::RetrieveColumnAsString(
                                $Connection.SessionId,
                                $tableId,
                                $column.Columnid,
                                [System.Text.Encoding]::Unicode
                            ) -split ';' -split ',')
                        $statusReport.IPAddress = $ipAddress.ForEach{
                            # potential for invalid ip address like empty string
                            try {
                                [void][ipaddress]::Parse($_)
                                $_
                            } catch {}
                        }
                    } elseif ($column.Name -in $stringColumns) {
                        $statusReport."$($column.Name)" = ([Microsoft.Isam.Esent.Interop.Api]::RetrieveColumnAsString(
                                $Connection.SessionId,
                                $tableId,
                                $column.Columnid,
                                [System.Text.Encoding]::Unicode
                            ) -split ';' -split ',')
                    } elseif ($column.Name -in $guidColumns) {
                        $statusReport."$($column.Name)" = [Microsoft.Isam.Esent.Interop.Api]::RetrieveColumnAsGuid(
                            $Connection.SessionId,
                            $tableId,
                            $column.Columnid
                        )
                    } elseif ($column.Name -in $deserializeColumns) {
                        $statusReport."$($column.Name)" = [Microsoft.Isam.Esent.Interop.Api]::DeserializeObjectFromColumn(
                            $Connection.SessionId,
                            $tableId,
                            $column.Columnid
                        ) | ConvertFrom-Json -ErrorAction SilentlyContinue
                    } elseif ($column.Name -eq 'AdditionalData') {
                        $statusReport."$($column.Name)" = [Microsoft.Isam.Esent.Interop.Api]::RetrieveColumnAsString(
                            $Connection.SessionId,
                            $tableId,
                            $column.Columnid,
                            [System.Text.Encoding]::Unicode
                        ) | ConvertFrom-Json -ErrorAction SilentlyContinue
                    } else {
                        $statusReport."$($column.Name)" = [Microsoft.Isam.Esent.Interop.Api]::RetrieveColumnAsString(
                            $Connection.SessionId,
                            $tableId,
                            $column.Columnid,
                            [System.Text.Encoding]::Unicode
                        )
                    }
                }

                if ($PSBoundParameters.ContainsKey('AgentId') -and $statusReport.Id -ne $AgentId) {
                    continue
                }

                if ($PSBoundParameters.ContainsKey('NodeName') -and $statusReport.NodeName -notlike $NodeName) {
                    continue
                }

                if ($PSBoundParameters.ContainsKey('FromStartTime') -and $statusReport.FromStartTime -ge $FromStartTime) {
                    continue
                }

                if ($PSBoundParameters.ContainsKey('ToStartTime') -and $statusReport.AgentId -le $ToStartTime) {
                    continue
                }

                if ($PSBoundParameters.ContainsKey('JobId') -and $statusReport.JobId -ne $JobId) {
                    continue
                }

                if ($OperationType -ne 'All' -and $statusReport.OperationType -ne $OperationType) {
                    continue
                }

                $statusReport
            }
        } catch {
            Write-Error -ErrorRecord $_ -ErrorAction Stop
        } 
    }
    end {
        Dismount-DSCPullServerESEDatabase -Connection $Connection
    }
}
