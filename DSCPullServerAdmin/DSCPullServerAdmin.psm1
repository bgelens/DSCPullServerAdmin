$sqlConnection = $null

function Connect-DSCPullServerAdminSQLInstance {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string] $InstanceName,

        [Parameter()]
        [pscredential] $Credential
    )
    process {
        if ($Credential) {
            $connectionString = "Server=$InstanceName;uid=$($Credential.UserName);pwd=$($Credential.GetNetworkCredential().Password);Trusted_Connection=False;"
        } else {
            $connectionString = "Server=$InstanceName;Integrated Security=True;"
        }
        $connection = [System.Data.SqlClient.SqlConnection]::new($connectionString)

        try {
            $connection.Open()
            Set-Variable -Name sqlConnection -Value $connection -Scope 1
        } catch {
            Set-Variable -Name sqlConnection -Value $null -Scope 1
            Write-Error -ErrorRecord $_
        }
    }
}

function Disconnect-DSCPullServerAdminSQLInstance {
    $script:sqlConnection.Close()
    $script:sqlConnection.Dispose()
    Set-Variable -Name sqlConnection -Value $null -Scope 1
}

function Set-DSCPullServerAdminSQLDatabase {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string] $Name
    )
    $script:sqlConnection.ChangeDatabase($Name)
}

function Get-DscPullServerAdminSQLRegistration {
    [cmdletbinding()]
    param (
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [Alias('NodeName')]
        [string] $Name
    )
    process {
        $command = $script:sqlConnection.CreateCommand()
        if ($PSBoundParameters.ContainsKey('Name')) {
            if ($Name.ToCharArray() -contains '*') {
                $Name = $Name.Replace('*','%')
            }
            $command.CommandText = "SELECT * FROM RegistrationData Where NodeName like '{0}'" -f $Name
        } else {
            $command.CommandText = 'SELECT * FROM RegistrationData'
        }
        Write-Verbose -Message "Query: `n $($command.CommandText)"
        $results = $command.ExecuteReader()
        $returnArray = [System.Collections.ArrayList]::new()
        foreach ($result in $results) {
            $table = @{}
            for ($i = 0; $i -lt $result.FieldCount; $i++) {
                $name = $result.GetName($i)
                switch ($name) {
                    'ConfigurationNames' {
                        $data = ($result[$i] | ConvertFrom-Json)
                    }
                    'IPAddress' {
                        $data = $result[$i] -Split ','
                    }
                    default {
                        $data = $result[$i]
                    }
                }
                [void] $table.Add($name, $data)
            }
            $null = $returnArray.Add($table)
        }
        $returnArray.ForEach{[pscustomobject]$_}
        $results.Close()
    }
}

function Get-DscPullServerAdminSQLReport {
    [cmdletbinding()]
    param (
        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [Alias('NodeName')]
        [string] $Name,

        [Parameter()]
        [datetime] $StartTime
    )
    process {
        $command = $script:sqlConnection.CreateCommand()
        if ($PSBoundParameters.ContainsKey('Name')) {
            if ($Name.ToCharArray() -contains '*') {
                $Name = $Name.Replace('*','%')
            }
            $query = "SELECT * FROM StatusReport Where NodeName like '{0}'" -f $Name
            if ($PSBoundParameters.ContainsKey('StartTime')) {
                $query += " and StartTime >= Convert(datetime, '{0}' )" -f $StartTime.ToString('yyyy-MM-dd HH:mm:ss')
            }
        } else {
            $query = 'SELECT * FROM StatusReport'
            if ($PSBoundParameters.ContainsKey('StartTime')) {
                $query += " Where StartTime >= Convert(datetime, '{0}' )" -f $StartTime.ToString('yyyy-MM-dd HH:mm:ss')
            }
        }
        $command.CommandText = $query
        Write-Verbose -Message "Query: `n $($command.CommandText)"
        $results = $command.ExecuteReader()
        $returnArray = [System.Collections.ArrayList]::new()
        foreach ($result in $results) {
            $table = @{}
            for ($i = 0; $i -lt $result.FieldCount; $i++) {
                $name = $result.GetName($i)
                switch ($name) {
                    { $_ -in 'StatusData', 'Errors'} {
                        $data = (($result[$i] | ConvertFrom-Json) | ConvertFrom-Json)
                    }
                    'AdditionalData' {
                        $data = ($result[$i] | ConvertFrom-Json)
                    }
                    'IPAddress' {
                        $data = $result[$i] -split ','
                    }
                    default {
                        $data = $result[$i]
                    }
                }
                [void] $table.Add($name, $data)
            }
            $null = $returnArray.Add($table)
        }
        $returnArray.ForEach{[pscustomobject]$_}
        $results.Close()
    }
}

function Set-DSCPullServerAdminSQLRegistration {
    [cmdletbinding()]
    param (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [Alias('NodeName')]
        [string] $Name,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string] $ConfigurationName
    )
    $command = $script:sqlConnection.CreateCommand()
    $query = "update RegistrationData set ConfigurationNames = '[ `"{0}`" ]' where NodeName = '{1}'" -f $ConfigurationName, $Name
    $command.CommandText = $query
    Write-Verbose -Message "Query: `n $($command.CommandText)"
    $command.ExecuteNonQuery()
}

function Import-DSCPullServerAdminSQLDataFromEDB {

}

function New-DSCPullServerAdminSQLDatabase {
    
}

Export-ModuleMember -Function *-DSCPullServerAdmin*
