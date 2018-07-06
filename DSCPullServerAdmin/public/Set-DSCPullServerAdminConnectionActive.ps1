<#
    .SYNOPSIS
    Set a connection that is stored in memory to be Active.

    .DESCRIPTION
    This function is used to set an existing connections for either SQL Databases
    or EDB files to be the Active connection.

    .PARAMETER Connection
    The connection object to be made active.

    .EXAMPLE
    $connection = Get-DSCPullServerAdminConnection -Index 4
    Set-DSCPullServerAdminConnectionActive -Connection $connection
#>
function Set-DSCPullServerAdminConnectionActive {
    [Diagnostics.CodeAnalysis.SuppressMessage('PSUseShouldProcessForStateChangingFunctions', '')]
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
