function Get-DSCPullServerESERegistration {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [DSCPullServerESEConnection] $Connection,

        [Parameter()]
        [guid] $AgentId,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [Alias('Name')]
        [string] $NodeName
    )
    begin {
        $table = 'RegistrationData'
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
                $nodeRegistration = [DSCNodeRegistration]::new()
                foreach ($column in ([Microsoft.Isam.Esent.Interop.Api]::GetTableColumns($Connection.SessionId, $tableId))) {
                    if ($column.Name -eq 'IPAddress') {
                        $nodeRegistration.IPAddress = ([Microsoft.Isam.Esent.Interop.Api]::RetrieveColumnAsString(
                                $Connection.SessionId,
                                $tableId,
                                $column.Columnid
                            ) -split ';' -split ',')
                    } elseif ($column.Name -eq 'ConfigurationNames') {
                        $nodeRegistration.ConfigurationNames = [Microsoft.Isam.Esent.Interop.Api]::DeserializeObjectFromColumn(
                            $Connection.SessionId,
                            $tableId,
                            $column.Columnid
                        )
                    } else {
                        $nodeRegistration."$($column.Name)" = [Microsoft.Isam.Esent.Interop.Api]::RetrieveColumnAsString(
                            $Connection.SessionId,
                            $tableId,
                            $column.Columnid
                        )
                    }
                }

                if ($PSBoundParameters.ContainsKey('NodeName') -and $nodeRegistration.NodeName -notlike $NodeName) {
                    continue
                }

                if ($PSBoundParameters.ContainsKey('AgentId') -and $nodeRegistration.AgentId -ne $AgentId) {
                    continue
                }

                $nodeRegistration
            }
        } catch {
            Write-Error -ErrorRecord $_ -ErrorAction Stop
        }
    }
    end {
        Dismount-DSCPullServerESEDatabase -Connection $Connection
    }
}
