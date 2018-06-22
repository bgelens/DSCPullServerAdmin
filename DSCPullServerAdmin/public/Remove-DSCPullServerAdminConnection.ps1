<#
    .SYNOPSIS
    Removes stored ESE and SQL connections from memory.

    .DESCRIPTION
    Connection objects created by New-DSCPullServerAdminConnection
    are stored in memory. This allows for multiple connections to
    exist simultaneously in the same session. When a connection can
    be disposed, this function allows you to remove it.

    .PARAMETER Connection
    The connection object to be removed from memory.

    .EXAMPLE
    Get-DSCPullServerAdminConnection -Index 4 | Remove-DSCPullServerAdminConnection
#>
function Remove-DSCPullServerAdminConnection {
    [Diagnostics.CodeAnalysis.SuppressMessage('PSUseShouldProcessForStateChangingFunctions', '')]
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [DSCPullServerConnection] $Connection
    )
    if ($Connection.Active) {
        Write-Warning -Message 'Removing Current Active Connection, please select or add a new one'
    }
    for ($i = 0; $i -lt $script:DSCPullServerConnections.Count; $i++) {
        if ($script:DSCPullServerConnections[$i].Equals($Connection)) {
            $script:DSCPullServerConnections.RemoveAt($i)
        }
    }
}
