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
