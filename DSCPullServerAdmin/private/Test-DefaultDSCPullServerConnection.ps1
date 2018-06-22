function Test-DefaultDSCPullServerConnection {
    [OutputType([bool])]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [AllowNull()]
        [DSCPullServerConnection] $Connection
    )

    if ($null -eq $Connection) {
        Write-Warning 'No active connection was found'
        $false
    } else {
        $true
    }
}
