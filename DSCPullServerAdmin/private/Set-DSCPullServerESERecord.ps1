function Set-DSCPullServerESERecord {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [DSCPullServerESEConnection] $Connection,

        [Parameter(Mandatory)]
        [object] $InputObject,

        [Parameter(ValueFromPipeline)]
        [object] $PipeLineObject,

        [switch] $Insert
    )
    process {
        $columnDictionary = [Microsoft.Isam.Esent.Interop.Api]::GetColumnDictionary($Connection.SessionId, $Connection.TableId)

        [Microsoft.Isam.Esent.Interop.Api]::JetBeginTransaction($Connection.SessionId)
        if ($Insert) {
            [Microsoft.Isam.Esent.Interop.Api]::JetPrepareUpdate($Connection.SessionId, $Connection.TableId, [Microsoft.Isam.Esent.Interop.JET_prep]::Insert)
        } else {
            [Microsoft.Isam.Esent.Interop.Api]::JetPrepareUpdate($Connection.SessionId, $Connection.TableId, [Microsoft.Isam.Esent.Interop.JET_prep]::Replace)
        }

        try {
            $columnDictionary.Keys.ForEach{
                if ($_ -in 'ConfigurationNames', 'Errors', 'StatusData') {
                    [Microsoft.Isam.Esent.Interop.Api]::SerializeObjectToColumn(
                        $Connection.SessionId,
                        $Connection.TableId,
                        $columnDictionary['ConfigurationNames'],
                        $InputObject.ConfigurationNames
                    )
                } elseif ($_ -eq 'IPAddress') {
                    [Microsoft.Isam.Esent.Interop.Api]::SetColumn(
                        $Connection.SessionId,
                        $Connection.TableId,
                        $columnDictionary[$_],
                        ($InputObject.$_ -join ';'),
                        [System.Text.Encoding]::Unicode
                    )
                } elseif ($_ -eq 'AdditionalData') {
                    [Microsoft.Isam.Esent.Interop.Api]::SetColumn(
                        $Connection.SessionId,
                        $Connection.TableId,
                        $columnDictionary[$_],
                        ($InputObject.$_ | ConvertTo-Json -Compress -Depth 100),
                        [System.Text.Encoding]::Unicode
                    )
                } elseif ($_ -in 'StartTime', 'EndTime', 'LastComplianceTime', 'LastHeartbeatTime', 'StatusCode', 'NodeCompliant') {
                    [Microsoft.Isam.Esent.Interop.Api]::SetColumn(
                        $Connection.SessionId,
                        $Connection.TableId,
                        $columnDictionary[$_],
                        $InputObject.$_
                    )
                } elseif ($_ -eq 'LastModifiedTime') {
                    [Microsoft.Isam.Esent.Interop.Api]::SetColumn(
                        $Connection.SessionId,
                        $Connection.TableId,
                        $columnDictionary[$_],
                        [datetime]::Now
                    )
                } elseif ($_ -in 'Dirty') {
                    [Microsoft.Isam.Esent.Interop.Api]::SetColumn(
                        $Connection.SessionId,
                        $Connection.TableId,
                        $columnDictionary[$_],
                        ([convert]::ToBoolean($InputObject.$_))
                    )
                } else {
                    [Microsoft.Isam.Esent.Interop.Api]::SetColumn(
                        $Connection.SessionId,
                        $Connection.TableId,
                        $columnDictionary[$_],
                        $InputObject.$_,
                        [System.Text.Encoding]::Unicode
                    )
                }
            }

            [Microsoft.Isam.Esent.Interop.Api]::JetUpdate($Connection.SessionId, $Connection.TableId)
            [Microsoft.Isam.Esent.Interop.Api]::JetCommitTransaction($Connection.SessionId, [Microsoft.Isam.Esent.Interop.CommitTransactionGrbit]::None)
        } catch {
            [Microsoft.Isam.Esent.Interop.Api]::JetRollback($Connection.SessionId, [Microsoft.Isam.Esent.Interop.RollbackTransactionGrbit]::None)
            Write-Error -ErrorRecord $_
        }
    }
}
