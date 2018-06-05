function Remove-DSCPullServerAdminConnection {
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
