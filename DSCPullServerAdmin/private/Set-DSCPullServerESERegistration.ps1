function Set-DSCPullServerESERegistration {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [DSCPullServerESEConnection] $Connection,

        [Parameter(Mandatory)]
        [DSCNodeRegistration] $InputObject,

        [Parameter(ValueFromPipeline)]
        [DSCNodeRegistration] $PipeLineObject,

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

        $columnDictionary.Keys.ForEach{
            if ($_ -eq 'ConfigurationNames') {
                [Microsoft.Isam.Esent.Interop.Api]::SerializeObjectToColumn(
                    $Connection.SessionId,
                    $Connection.TableId,
                    $columnDictionary['ConfigurationNames'],
                    $InputObject.ConfigurationNames
                )
            } elseif ('IPAddress') {
                [Microsoft.Isam.Esent.Interop.Api]::SetColumn(
                    $Connection.SessionId,
                    $Connection.TableId,
                    $columnDictionary[$_],
                    ($InputObject.$_ -join ';'),
                    [System.Text.Encoding]::Unicode
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
    }
}
