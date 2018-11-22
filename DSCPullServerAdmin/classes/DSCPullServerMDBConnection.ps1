class DSCPullServerMDBConnection : DSCPullServerConnection {
    [string] $MDBFilePath

    DSCPullServerMDBConnection () : base([DSCPullServerConnectionType]::MDB) { }

    DSCPullServerMDBConnection ([string]$Path) : base([DSCPullServerConnectionType]::MDB) {
        $resolvedPath = Resolve-Path $Path -ErrorAction SilentlyContinue
        if ($null -eq $resolvedPath) {
            throw "File $Path is invalid"
        } else {
            $this.MDBFilePath = $resolvedPath.ProviderPath
        }
    }

    [string] ConnectionString () {
        return "Provider=Microsoft.ACE.OLEDB.16.0;Data Source=$($this.MDBFilePath);Persist Security Info=False"
    }
}

