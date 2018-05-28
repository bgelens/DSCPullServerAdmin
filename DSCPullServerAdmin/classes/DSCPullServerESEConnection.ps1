class DSCPullServerESEConnection : DSCPullServerConnection {
    [string] $ESEFilePath
    hidden [object] $Instance
    hidden [object] $SessionId
    hidden [object] $DbId

    DSCPullServerESEConnection () : base([DSCPullServerConnectionType]::ESE) { }

    DSCPullServerESEConnection ([string]$Path) : base([DSCPullServerConnectionType]::ESE) {
        $this.ESEFilePath = (Resolve-Path $Path).ProviderPath
    }
}
