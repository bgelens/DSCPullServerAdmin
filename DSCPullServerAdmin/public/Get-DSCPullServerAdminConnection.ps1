<#
    .SYNOPSIS
    Get stored ESE and SQL connections from memory.

    .DESCRIPTION
    Connection objects created by New-DSCPullServerAdminConnection
    are stored in memory. This allows for multiple connections to
    exist simultaneously in the same session. This function will
    return the existing connections and allows for multiple types of
    filtering.

    .PARAMETER Type
    Filter output on Connection type.

    .PARAMETER OnlyShowActive
    Only return the current Active connection.

    .PARAMETER Index
    Return a specific Connection based on it's index number.

    .EXAMPLE
    Get-DSCPullServerAdminConnection -OnlyShowActive

    .EXAMPLE
    Get-DSCPullServerAdminConnection
#>
function Get-DSCPullServerAdminConnection {
    [OutputType([DSCPullServerSQLConnection])]
    [OutputType([DSCPullServerESEConnection])]
    [CmdletBinding()]
    param (
        [Parameter()]
        [DSCPullServerConnectionType] $Type,

        [switch] $OnlyShowActive,

        [Parameter()]
        [uint16] $Index
    )
    if ($PSBoundParameters.ContainsKey('Type')) {
        $result = $script:DSCPullServerConnections | Where-Object -FilterScript {
            $_.Type -eq $Type
        }
    } else {
        $result = $script:DSCPullServerConnections
    }

    if ($PSBoundParameters.ContainsKey('Index')) {
        $result = $result | Where-Object -FilterScript {
            $_.Index -eq $Index
        }
    }

    if ($OnlyShowActive) {
        $result | Where-Object -FilterScript {
            $_.Active
        }
    } else {
        $result
    }
}
