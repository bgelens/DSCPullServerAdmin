class DSCNodeRegistration : DSCBaseClass {
    [Guid] $AgentId

    [string] $LCMVersion

    [string] $NodeName

    [IPAddress[]] $IPAddress

    [string[]] $ConfigurationNames

    DSCNodeRegistration () : base([DSCDatabaseTable]::RegistrationData) { }

    DSCNodeRegistration ([System.Data.Common.DbDataRecord] $Input) : base([DSCDatabaseTable]::RegistrationData) {
        for ($i = 0; $i -lt $Input.FieldCount; $i++) {
            $name = $Input.GetName($i)
            $data = $null
            switch ($name) {
                'ConfigurationNames' {
                    $data = ($Input[$i] | ConvertFrom-Json)
                }
                'IPAddress' {
                    $data = ($Input[$i] -split ',') -split ';' | ForEach-Object -Process {
                        if ($_ -ne [string]::Empty) {
                            $_
                        }
                    }
                }
                default {
                    $data = $Input[$i]
                }
            }
            $this."$name" = $data
        }
    }
}
