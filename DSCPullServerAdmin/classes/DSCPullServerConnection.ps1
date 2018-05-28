class DSCPullServerConnection {
    hidden [DSCPullServerConnectionType] $_Type

    [uint16] $Index

    [bool] $Active

    DSCPullServerConnection ([DSCPullServerConnectionType]$Type) {
        $this._Type = $Type
        $this | Add-Member -MemberType ScriptProperty -Name Type -Value {
            return $this._Type
        } -SecondValue {
            Write-Warning 'This is a readonly property!'
        }
    }
}
