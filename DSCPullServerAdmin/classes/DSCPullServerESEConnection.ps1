class DSCPullServerESEConnection : DSCPullServerConnection {
    [string] $ESEFilePath
    hidden [object] $Instance
    hidden [object] $SessionId
    hidden [object] $DbId
    hidden [object] $TableId

    DSCPullServerESEConnection () : base([DSCPullServerConnectionType]::ESE) { }

    DSCPullServerESEConnection ([string]$Path) : base([DSCPullServerConnectionType]::ESE) {
        $resolvedPath = Resolve-Path $Path -ErrorAction SilentlyContinue
        if ($null -eq $resolvedPath) {
            throw "File $Path is invalid"
        } else {
            $this.ESEFilePath = $resolvedPath.ProviderPath
        }
    }
}
