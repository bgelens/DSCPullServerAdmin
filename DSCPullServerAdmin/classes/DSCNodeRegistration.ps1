class DSCNodeRegistration {
    [Guid] $AgentId

    [string] $LCMVersion

    [string] $NodeName

    [IPAddress[]] $IPAddress

    [string[]] $ConfigurationNames

    DSCNodeRegistration () {}

    DSCNodeRegistration ([System.Data.Common.DbDataRecord] $Input) {
        for ($i = 0; $i -lt $Input.FieldCount; $i++) {
            $name = $Input.GetName($i)
            $data = $null
            switch ($name) {
                'ConfigurationNames' {
                    $data = ($Input[$i] | ConvertFrom-Json)
                }
                'IPAddress' {
                    $data = ($Input[$i] -split ',') -split ';'
                }
                default {
                    $data = $Input[$i]
                }
            }
            $this."$name" = $data
        }
    }

    [string] GetSQLUpdate () {
        $query = "UPDATE RegistrationData Set {0} WHERE AgentId = '{1}'" -f @(
            (($this | Get-Member -MemberType Property).Where{
                $_.Name -ne 'AgentId'
            }.foreach{
                if ($_.Name -eq 'ConfigurationNames') {
                    if ($this.ConfigurationNames.Count -ge 1) {
                        "$($_.Name) = '[`"{0}`"]'" -f ($this."$($_.Name)" -join '","')
                    } else {
                        "$($_.Name) = '[]'"
                    }
                } elseif ($_.Name -eq 'IPAddress') {
                    "$($_.Name) = '{0}'" -f ($this."$($_.Name)" -join ';')
                } else {
                    if ($_.Definition.Split(' ')[0] -eq 'datetime') {
                        "$($_.Name) = '{0}'" -f $this."$($_.Name)".ToString('yyyy-MM-dd HH:mm:ss')
                    } else {
                        "$($_.Name) = '{0}'" -f $this."$($_.Name)"
                    }
                }
            } -join ','),
            $this.AgentId
        )
        return $query
    }

    [string] GetSQLInsert () {
        $query = ("INSERT INTO RegistrationData ({0}) VALUES ({1})" -f @(
            (($this | Get-Member -MemberType Property).Name -join ','),
            (($this | Get-Member -MemberType Property).ForEach{
                if ($_.Name -eq 'ConfigurationNames') {
                    if ($this.ConfigurationNames.Count -ge 1) {
                        "'[`"{0}`"]'" -f ($this."$($_.Name)" -join '","')
                    } else {
                        "'[]'"
                    }
                } elseif ($_.Name -eq 'IPAddress') {
                    "'{0}'" -f ($this."$($_.Name)" -join ';')
                } else {
                    if ($_.Definition.Split(' ')[0] -eq 'datetime') {
                        "'{0}'" -f $this."$($_.Name)".ToString('yyyy-MM-dd HH:mm:ss')
                    } else {
                        "'{0}'" -f $this."$($_.Name)"
                    }
                }
            } -join ',')
        ))
        return $query
    }

    [string] GetSQLDelete () {
        return ("DELETE FROM RegistrationData WHERE AgentId = '{0}'" -f $this.AgentId)
    }
}
