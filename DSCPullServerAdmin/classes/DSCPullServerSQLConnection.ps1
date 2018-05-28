class DSCPullServerSQLConnection : DSCPullServerConnection {
    [string] $SQLServer

    [pscredential] $Credential

    [string] $Database

    DSCPullServerSQLConnection () : base([DSCPullServerConnectionType]::SQL) { }

    DSCPullServerSQLConnection ([string]$Server, [pscredential]$Credential, [string]$Database) : base([DSCPullServerConnectionType]::SQL) {
        $this.SQLServer = $Server
        $this.Credential = $Credential
        $this.Database = $Database
    }

    DSCPullServerSQLConnection ([string]$Server, [pscredential]$Credential) : base([DSCPullServerConnectionType]::SQL) {
        $this.SQLServer = $Server
        $this.Credential = $Credential
        $this.Database = 'DSC'
    }

    DSCPullServerSQLConnection ([string]$Server, [string]$Database) : base([DSCPullServerConnectionType]::SQL) {
        $this.SQLServer = $Server
        $this.Database = $Database
    }

    DSCPullServerSQLConnection ([string]$Server) : base([DSCPullServerConnectionType]::SQL) {
        $this.SQLServer = $Server
    }

    [string] ConnectionString () {
        if ($this.Credential -and $this.Database) {
            return 'Server={0};uid={1};pwd={2};Trusted_Connection=False;Database={3};' -f @(
                $this.SQLServer,
                $this.Credential.UserName,
                $this.Credential.GetNetworkCredential().Password,
                $this.Database
            )
        } elseif (($null -eq $this.Credential) -and $this.Database) {
            return 'Server={0};Integrated Security=True;Database={1};' -f @(
                $this.SQLServer,
                $this.Database
            )
        } elseif ($this.Credential -and -not $this.Database) {
            return 'Server={0};uid={1};pwd={2};Trusted_Connection=False;' -f @(
                $this.SQLServer,
                $this.Credential.UserName,
                $this.Credential.GetNetworkCredential().Password
            )
        } else {
            return 'Server={0};Integrated Security=True;' -f @(
                $this.SQLServer
            )
        }
    }
}
