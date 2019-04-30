function Set-DSCPullServerESERecord {
    [CmdletBinding()]
    [Diagnostics.CodeAnalysis.SuppressMessage('PSUseShouldProcessForStateChangingFunctions', '')]
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
                if ($InputObject.GetType().Name -eq 'DSCNodeStatusReport' -and $_ -eq 'JobId' -and -not $Insert) {
                    #primary key cannot be updated
                    return
                } elseif ($InputObject.GetType().Name -eq 'DSCNodeRegistration' -and $_ -eq 'AgentId' -and -not $Insert) {
                    #primary key cannot be updated
                    return
                } elseif ($InputObject.GetType().Name -eq 'DSCDevice' -and $_ -eq 'Targetname' -and -not $Insert) {
                    #primary key cannot be updated
                    return
                } elseif ($_ -in 'ConfigurationNames', 'Errors', 'StatusData') {
                    [Microsoft.Isam.Esent.Interop.Api]::SerializeObjectToColumn(
                        $Connection.SessionId,
                        $Connection.TableId,
                        $columnDictionary[$_],
                        [Collections.Generic.List[String]]$InputObject.$_
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
