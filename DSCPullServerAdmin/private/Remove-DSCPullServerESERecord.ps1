function Remove-DSCPullServerESERecord {
    [CmdletBinding()]
    [Diagnostics.CodeAnalysis.SuppressMessage('PSUseShouldProcessForStateChangingFunctions', '')]
    param(
        [Parameter(Mandatory)]
        [DSCPullServerESEConnection] $Connection,

        [Parameter(ValueFromPipeline)]
        [object] $PipeLineObject
    )
    process {
        [Microsoft.Isam.Esent.Interop.Api]::JetDelete($Connection.SessionId, $Connection.TableId)
    }
}
