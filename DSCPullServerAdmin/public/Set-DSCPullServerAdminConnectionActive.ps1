function Set-DSCPullServerAdminConnectionActive {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [DSCPullServerConnection] $Connection
    )
    $currentActive = Get-DSCPullServerAdminConnection -OnlyShowActive
    if ($null -ne $currentActive) {
        $currentActive.Active = $false
    }
    $Connection.Active = $true
}
