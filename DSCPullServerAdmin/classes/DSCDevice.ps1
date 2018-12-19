class DSCDevice : DSCBaseClass {
    [string] $TargetName

    [guid] $ConfigurationID

    [string] $ServerCheckSum

    [string] $TargetCheckSum

    [bool] $NodeCompliant

    [nullable[datetime]] $LastComplianceTime

    [nullable[datetime]] $LastHeartbeatTime

    [bool] $Dirty

    [int32] $StatusCode

    hidden [string] $_status = "$($this | Add-Member -MemberType ScriptProperty -Name Status -Value {
        $this.GetStatus()
    })"

    DSCDevice () : base([DSCDatabaseTable]::Devices) { }

    DSCDevice ([System.Data.Common.DbDataRecord] $Input) : base([DSCDatabaseTable]::Devices) {
        for ($i = 0; $i -lt $Input.FieldCount; $i++) {
            $name = $Input.GetName($i)
            if (([DBNull]::Value).Equals($Input[$i])) {
                $this."$name" = $null
            } else {
                $this."$name" = $Input[$i]
            }
        }
    }

    [string] GetStatus () {
        $deviceStatusCodeMap = @{
            0 = 'Configuration was applied successfully'
            1 = 'Download Manager initialization failure'
            2 = 'Get configuration command failure'
            3 = 'Unexpected get configuration response from pull server'
            4 = 'Configuration checksum file read failure'
            5 = 'Configuration checksum validation failure'
            6 = 'Invalid configuration file'
            7 = 'Available modules check failure'
            8 = 'Invalid configuration Id In meta-configuration'
            9 = 'Invalid DownloadManager CustomData in meta-configuration'
            10 = 'Get module command failure'
            11 = 'Get Module Invalid Output'
            12 = 'Module checksum file not found'
            13 = 'Invalid module file'
            14 = 'Module checksum validation failure'
            15 = 'Module extraction failed'
            16 = 'Module validation failed'
            17 = 'Downloaded module is invalid'
            18 = 'Configuration file not found'
            19 = 'Multiple configuration files found'
            20 = 'Configuration checksum file not found'
            21 = 'Module not found'
            22 = 'Invalid module version format'
            23 = 'Invalid configuration Id format'
            24 = 'Get Action command failed'
            25 = 'Invalid checksum algorithm'
            26 = 'Get Lcm Update command failed'
            27 = 'Unexpected Get Lcm Update response from pull server'
            28 = 'Invalid Refresh Mode in meta-configuration'
            29 = 'Invalid Debug Mode in meta-configuration'
        }
        return $deviceStatusCodeMap[$this.StatusCode]
    }
}
