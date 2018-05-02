Import-Module $PSScriptRoot\DSCPullServerAdmin.dll -Prefix ESE

class DSCDevice {
    [string]
    $TargetName

    [guid]
    $ConfigurationID

    [string]
    $ServerCheckSum

    [string]
    $TargetCheckSum

    [bool]
    $NodeCompliant

    [datetime]
    $LastComplianceTime

    [datetime]
    $LastHeartbeatTime

    [bool]
    $Dirty

    [int32]
    $StatusCode

    DSCDevice ([System.Data.Common.DbDataRecord] $Input) {
        for ($i = 0; $i -lt $Input.FieldCount; $i++) {
            $name = $Input.GetName($i)

            $this."$name" = $Input[$i]
        }
    }
}

class DSCNodeRegistration {
    [Guid]
    $AgentId

    [string]
    $LCMVersion

    [string]
    $NodeName

    [IPAddress[]]
    $IPAddress

    [string[]]
    $ConfigurationNames

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
}

class DSCNodeStatusReport {
    [Guid]
    $JobId

    [Guid]
    $Id

    [string]
    $OperationType

    [string]
    $RefreshMode

    [string]
    $Status

    [string]
    $LCMVersion

    [string]
    $ReportFormatVersion

    [string]
    $ConfigurationVersion

    [string]
    $NodeName

    [IPAddress[]]
    $IPAddress

    [datetime]
    $StartTime

    [datetime]
    $EndTime

    [PSObject[]]
    $Errors

    [PSObject[]]
    $StatusData

    [bool]
    $RebootRequested

    [PSObject[]]
    $AdditionalData

    DSCNodeStatusReport ([System.Data.Common.DbDataRecord] $Input) {
        for ($i = 0; $i -lt $Input.FieldCount; $i++) {
            $name = $Input.GetName($i)
            $data = $null
            switch ($name) {
                { $_ -in 'StatusData', 'Errors'} {
                    $data = (($Input[$i] | ConvertFrom-Json) | ConvertFrom-Json)
                }
                'AdditionalData' {
                    $data = ($Input[$i] | ConvertFrom-Json)
                }
                'IPAddress' {
                    $data = ($Input[$i] -split ',') -split ';'
                }
                default {
                    $data = $Input[$i]
                }
            }
            if ($false -eq [string]::IsNullOrEmpty($data)) {
                $this."$name" = $data
            }
        }
    }
}

function New-DSCPullServerAdminRegistration {
    [cmdletbinding(DefaultParameterSetName = "SQL")]
    param (
        [Parameter(Mandatory, ParameterSetName = "ESE")]
        [string]
        $ESEFilePath,

        [Parameter(Mandatory, ParameterSetName = "SQL")]
        [string]
        $SQLServer,

        [Parameter(ParameterSetName = "SQL")]
        [pscredential]
        $SQLCredential,

        [Parameter(ValueFromPipelineByPropertyName)]
        [guid]
        $AgentId,

        [Parameter(ValueFromPipelineByPropertyName)]
        [string]
        $LCMVersion,

        [Parameter(ValueFromPipelineByPropertyName)]
        [string]
        $NodeName,

        [Parameter(ValueFromPipelineByPropertyName)]
        [IPAddress[]]
        $IPAddress,

        [Parameter(ValueFromPipelineByPropertyName)]
        [string[]]
        $ConfigurationNames
    )

    process {
        switch ($PSCmdlet.ParameterSetName) {

            'ESE' {
                Write-Warning "Add new agent registrations to the ESE database is not currently supported"
            }

            'SQL' {
                $Command = "INSERT INTO RegistrationData ({0}) VALUES ({1})"

                $Columns = @("AgentId", "LCMVersion", "NodeName", "IPAddress", "ConfigurationNames")

                $InsertData = @{}

                $PSBoundParameters.Keys | Where-Object -PipelineVariable Column -FilterScript {
                    $_ -in $Columns
                } | ForEach-Object -Process {
                    switch ($Column) {
                        'IPAddress' {
                            $InsertData.Add($Column, "'$($PSBoundParameters[$Column] -join ',')'")
                        }

                        'ConfigurationNames' {
                            $InsertData.Add($Column, "'$($PSBoundParameters[$Column] | ConvertTo-Json -Compress)'")
                        }

                        default {
                            $InsertData.Add($Column, "'$($PSBoundParameters[$Column])'")
                        }
                    }
                }

                $Command = $Command -f ($InsertData.Keys -join ','), ($InsertData.Values -join ',')

                $Output = Invoke-DSCPullServerSQLCommand @PSBoundParameters -CommandType Set -Script $Command
                Write-Verbose $Output
            }
        }
    }
}

function Set-DSCPullServerAdminRegistration {
    [cmdletbinding(DefaultParameterSetName = "SQL")]
    param (
        [Parameter(Mandatory, ParameterSetName = "ESE")]
        [string]
        $ESEFilePath,

        [Parameter(Mandatory, ParameterSetName = "SQL")]
        [string]
        $SQLServer,

        [Parameter(ParameterSetName = "SQL")]
        [pscredential]
        $SQLCredential,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [guid]
        $AgentId,

        [Parameter()]
        [string]
        $LCMVersion,

        [Parameter()]
        [string]
        $NodeName,

        [Parameter()]
        [IPAddress[]]
        $IPAddress,

        [Parameter()]
        [string[]]
        $ConfigurationNames
    )

    process {
        switch ($PSCmdlet.ParameterSetName) {

            'ESE' {
                Write-Warning "Only updating agent configuration names in the ESE database is currently supported"

                Set-ESEDSCPullServerAdminRegistration -AgentId $AgentId -ConfigurationName $ConfigurationNames
            }

            'SQL' {
                $Command = "UPDATE RegistrationData SET {0} WHERE AgentId = '$AgentId'"

                $Columns = @("LCMVersion", "NodeName", "IPAddress", "ConfigurationNames")

                $UpdateData = @()

                $PSBoundParameters.Keys | Where-Object -PipelineVariable Column -FilterScript {
                    $_ -in $Columns
                } | ForEach-Object -Process {
                    switch ($Column) {
                        'IPAddress' {
                            $UpdateData += "$Column = '$($PSBoundParameters[$Column] -join ',')'"
                        }

                        'ConfigurationNames' {
                            $UpdateData += "$Column = '$($PSBoundParameters[$Column] | ConvertTo-Json -Compress)'"
                        }

                        default {
                            $UpdateData += "$Column = '$($PSBoundParameters[$Column])'"
                        }
                    }
                }

                $Command = $Command -f ($UpdateData -join ',')

                $Output = Invoke-DSCPullServerSQLCommand @PSBoundParameters -CommandType Set -Script $Command
                Write-Verbose "Agents Updated: $Output"
            }
        }
    }
}

function Remove-DSCPullServerAdminRegistration {
    [cmdletbinding(DefaultParameterSetName = "SQL")]
    param (
        [Parameter(Mandatory, ParameterSetName = "ESE")]
        [string]
        $ESEFilePath,

        [Parameter(Mandatory, ParameterSetName = "SQL")]
        [string]
        $SQLServer,

        [Parameter(ParameterSetName = "SQL")]
        [pscredential]
        $SQLCredential,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [guid]
        $AgentId
    )

    process {
        switch ($PSCmdlet.ParameterSetName) {

            'ESE' {
                Remove-ESEDSCPullServerAdminRegistration -AgentId $AgentId
            }

            'SQL' {
                $Command = "DELETE FROM RegistrationData WHERE AgentId = '$AgentId'"

                $Output = Invoke-DSCPullServerSQLCommand @PSBoundParameters -CommandType Set -Script $Command
                Write-Verbose "Agents Deleted: $Output"
            }
        }
    }
}

function Get-DSCPullServerAdminRegistration {
    [cmdletbinding(DefaultParameterSetName = "SQL")]
    param (
        [Parameter(Mandatory, ParameterSetName = "ESE")]
        [string]
        $ESEFilePath,

        [Parameter(Mandatory, ParameterSetName = "SQL")]
        [string]
        $SQLServer,

        [Parameter(ParameterSetName = "SQL")]
        [pscredential]
        $SQLCredential,

        [Parameter()]
        [guid]
        $AgentId,

        [Parameter()]
        [String]
        $NodeName
    )

    process {
        switch ($PSCmdlet.ParameterSetName) {

            'ESE' {
                $Params = @{}
                if ($PSBoundParameters.ContainsKey("AgentId")) {
                    $Params.Add("AgentId", $AgentId)
                }
                if ($PSBoundParameters.ContainsKey("NodeName")) {
                    $Params.Add("NodeName", $NodeName)
                }
                Get-ESEDSCPullServerAdminRegistration @Params
            }

            'SQL' {
                $Command = "SELECT * FROM RegistrationData"
                $Filters = @()
                if ($PSBoundParameters.ContainsKey("AgentId")) {
                    $Filters += "AgentId = '{0}'" -f $AgentId
                }
                if ($PSBoundParameters.ContainsKey("NodeName")) {
                    $Filters += "NodeName = '{0}'" -f $NodeName
                }

                if ($Filters.Count -gt 0) {
                    $Command += " WHERE {0}" -f ($Filters -join ' AND ')
                }

                (Invoke-DSCPullServerSQLCommand @PSBoundParameters -CommandType Get -Script $Command) | ForEach-Object {
                    [DSCNodeRegistration]::New($_)
                }
            }
        }
    }
}

function New-DSCPullServerAdminDevice {
    [cmdletbinding(DefaultParameterSetName = "SQL")]
    param (
        [Parameter(Mandatory, ParameterSetName = "ESE")]
        [string]
        $ESEFilePath,

        [Parameter(Mandatory, ParameterSetName = "SQL")]
        [string]
        $SQLServer,

        [Parameter(ParameterSetName = "SQL")]
        [pscredential]
        $SQLCredential,

        [Parameter(ValueFromPipelineByPropertyName)]
        [guid]
        $ConfigurationID,

        [Parameter(ValueFromPipelineByPropertyName)]
        [string]
        $TargetName,

        [Parameter(ValueFromPipelineByPropertyName)]
        [string]
        $ServerCheckSum,

        [Parameter(ValueFromPipelineByPropertyName)]
        [string]
        $TargetCheckSum,

        [Parameter(ValueFromPipelineByPropertyName)]
        [bool]
        $NodeCompliant,

        [Parameter(ValueFromPipelineByPropertyName)]
        [datetime]
        $LastComplianceTime,

        [Parameter(ValueFromPipelineByPropertyName)]
        [datetime]
        $LastHeartbeatTime,

        [Parameter(ValueFromPipelineByPropertyName)]
        [bool]
        $Dirty,

        [Parameter(ValueFromPipelineByPropertyName)]
        [int32]
        $StatusCode
    )

    process {
        switch ($PSCmdlet.ParameterSetName) {

            'ESE' {
                Write-Warning "Add new agent registrations to the ESE database is not currently supported"
            }

            'SQL' {
                $Command = "INSERT INTO Devices ({0}) VALUES ({1})"

                $Columns = @("TargetName", "ConfigurationID", "ServerCheckSum", "TargetCheckSum", "NodeCompliant", "LastComplianceTime", "LastHeartbeatTime", "Dirty", "StatusCode")

                $InsertData = @{}

                $PSBoundParameters.Keys | Where-Object -PipelineVariable Column -FilterScript {
                    $_ -in $Columns
                } | ForEach-Object -Process {
                    $InsertData.Add($Column, "'$($PSBoundParameters[$Column])'")
                }

                $Command = $Command -f ($InsertData.Keys -join ','), ($InsertData.Values -join ',')

                $Output = Invoke-DSCPullServerSQLCommand @PSBoundParameters -CommandType Set -Script $Command
                Write-Verbose $Output
            }
        }
    }
}

function Set-DSCPullServerAdminDevice {
    [cmdletbinding(DefaultParameterSetName = "SQL")]
    param (
        [Parameter(Mandatory, ParameterSetName = "ESE")]
        [string]
        $ESEFilePath,

        [Parameter(Mandatory, ParameterSetName = "SQL")]
        [string]
        $SQLServer,

        [Parameter(ParameterSetName = "SQL")]
        [pscredential]
        $SQLCredential,

        [Parameter()]
        [guid]
        $ConfigurationID,

        [Parameter(ValueFromPipelineByPropertyName)]
        [string]
        $TargetName,

        [Parameter()]
        [string]
        $ServerCheckSum,

        [Parameter()]
        [string]
        $TargetCheckSum,

        [Parameter()]
        [bool]
        $NodeCompliant,

        [Parameter()]
        [datetime]
        $LastComplianceTime,

        [Parameter()]
        [datetime]
        $LastHeartbeatTime,

        [Parameter()]
        [bool]
        $Dirty,

        [Parameter()]
        [int32]
        $StatusCode
    )

    process {
        switch ($PSCmdlet.ParameterSetName) {

            'ESE' {
                Write-Warning "Updating version 1 agents in the ESE database is not currently supported"
            }

            'SQL' {
                $Command = "UPDATE Devices SET {0} WHERE TargetName = '$TargetName'"

                $Columns = @("ConfigurationID", "ServerCheckSum", "TargetCheckSum", "NodeCompliant", "LastComplianceTime", "LastHeartbeatTime", "Dirty", "StatusCode")

                $UpdateData = @()

                $PSBoundParameters.Keys | Where-Object -PipelineVariable Column -FilterScript {
                    $_ -in $Columns
                } | ForEach-Object -Process {
                    $UpdateData += "$Column = '$($PSBoundParameters[$Column])'"
                }

                $Command = $Command -f ($UpdateData -join ',')

                $Output = Invoke-DSCPullServerSQLCommand @PSBoundParameters -CommandType Set -Script $Command
                Write-Verbose "Agents Updated: $Output"
            }
        }
    }
}

function Remove-DSCPullServerAdminDevice {
    [cmdletbinding(DefaultParameterSetName = "SQL")]
    param (
        [Parameter(Mandatory, ParameterSetName = "ESE")]
        [string]
        $ESEFilePath,

        [Parameter(Mandatory, ParameterSetName = "SQL")]
        [string]
        $SQLServer,

        [Parameter(ParameterSetName = "SQL")]
        [pscredential]
        $SQLCredential,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [string]
        $TargetName
    )

    process {
        switch ($PSCmdlet.ParameterSetName) {

            'ESE' {
                Write-Warning "Removing version 1 agents in the ESE database is not currently supported"
            }

            'SQL' {
                $Command = "DELETE FROM Devices WHERE TargetName = '$TargetName'"

                $Output = Invoke-DSCPullServerSQLCommand @PSBoundParameters -CommandType Set -Script $Command
                Write-Verbose "Agents Deleted: $Output"
            }
        }
    }
}

function Get-DSCPullServerAdminDevice {
    [cmdletbinding(DefaultParameterSetName = "SQL")]
    param (
        [Parameter(Mandatory, ParameterSetName = "ESE")]
        [string]
        $ESEFilePath,

        [Parameter(Mandatory, ParameterSetName = "SQL")]
        [string]
        $SQLServer,

        [Parameter(ParameterSetName = "SQL")]
        [pscredential]
        $SQLCredential,

        [Parameter()]
        [guid]
        $AgentId,

        [Parameter()]
        [String]
        $NodeName
    )

    process {
        switch ($PSCmdlet.ParameterSetName) {

            'ESE' {
                $Params = @{}
                if ($PSBoundParameters.ContainsKey("AgentId")) {
                    $Params.Add("AgentId", $AgentId)
                }
                if ($PSBoundParameters.ContainsKey("NodeName")) {
                    $Params.Add("NodeName", $NodeName)
                }
                Get-ESEDSCPullServerAdminRegistration @Params
            }

            'SQL' {
                $Command = "SELECT * FROM RegistrationData"
                $Filters = @()
                if ($PSBoundParameters.ContainsKey("AgentId")) {
                    $Filters += "AgentId = '{0}'" -f $AgentId
                }
                if ($PSBoundParameters.ContainsKey("NodeName")) {
                    $Filters += "NodeName = '{0}'" -f $NodeName
                }

                if ($Filters.Count -gt 0) {
                    $Command += " WHERE {0}" -f ($Filters -join ' AND ')
                }

                (Invoke-DSCPullServerSQLCommand @PSBoundParameters -CommandType Get -Script $Command) | ForEach-Object {
                    [DSCNodeRegistration]::New($_)
                }
            }
        }
    }
}

function Invoke-DSCPullServerSQLCommand {
    [cmdletbinding()]
    param(
        [Parameter(Mandatory)]
        [Alias("SQLServer")]
        [string]
        $InstanceName,

        [Parameter()]
        [Alias("SQLCredential")]
        [pscredential]
        $Credential,

        [Parameter()]
        [string]
        $Database = "DSC",

        [Parameter(Mandatory, ValueFromPipeline)]
        [string]
        $Script,

        [Parameter()]
        [ValidateSet("Get", "Set")]
        [string]
        $CommandType = "Set",

        [parameter(ValueFromRemainingArguments, DontShow)]
        $DroppedParams
    )

    begin {
        if ($Credential) {
            $ConnectionString = "Server=$InstanceName;uid=$($Credential.UserName);pwd=$($Credential.GetNetworkCredential().Password);Trusted_Connection=False;Initial Catalog=$Database"
        } else {
            $ConnectionString = "Server=$InstanceName;Integrated Security=True;Initial Catalog=$Database"
        }
        $Connection = [System.Data.SqlClient.SqlConnection]::new($ConnectionString)
        $Connection.Open()
    }

    process {
        try {
            $Command = $Connection.CreateCommand()

            $Command.CommandText = $Script

            Write-Verbose ("Invoking command: {0}" -f $Script)

            switch ($CommandType) {
                "Get" {
                    $Command.ExecuteReader()
                }

                "Set" {
                    $Command.ExecuteNonQuery()
                }
            }
        } catch [System.Data.SqlClient.SqlException] {
            Write-Error -Message "Something went wrong with SQL: $($_.Exception.Message)" -Exception $_.Exception
        } catch {
            write-warning $_.Exception.Message
        } finally {
            if ($false -eq $?) {
                $Connection.Close()
                $Connection.Dispose()
            }
        }
    }

    end {
        $Connection.Close()
        $Connection.Dispose()
    }
}

function Get-DSCPullServerAdminStatusReport {
    [cmdletbinding(DefaultParameterSetName = "SQL")]
    param (
        [Parameter(Mandatory, ParameterSetName = "ESE")]
        [string]
        $ESEFilePath,

        [Parameter(Mandatory, ParameterSetName = "SQL")]
        [string]
        $SQLServer,

        [Parameter(ParameterSetName = "SQL")]
        [pscredential]
        $SQLCredential,

        [Parameter(ValueFromPipelineByPropertyName)]
        [guid]
        $AgentId,

        [Parameter()]
        [datetime]
        $FromStartTime,

        [Parameter()]
        [datetime]
        $ToStartTime
    )

    process {
        switch ($PSCmdlet.ParameterSetName) {

            'ESE' {
                $Params = @{}
                if ($PSBoundParameters.ContainsKey("FromStartTime")) {
                    $Params.Add("FromStartTime", $FromStartTime)
                }
                if ($PSBoundParameters.ContainsKey("ToStartTime")) {
                    $Params.Add("ToStartTime", $ToStartTime)
                }
                Get-ESEDSCPullServerAdminReport -NodeName $NodeName @Params
            }

            'SQL' {
                $Command = "SELECT * FROM StatusReport"
                $Filters = @("Id = '{0}'" -f $AgentId)

                if ($PSBoundParameters.ContainsKey("FromStartTime")) {
                    $Filters += "StartTime >= '{0}'" -f (Get-Date $FromStartTime -f s)
                }

                if ($PSBoundParameters.ContainsKey("ToStartTime")) {
                    $Filters += "StartTime <= '{0}'" -f (Get-Date $ToStartTime -f s)
                }

                if ($Filters.Count -gt 0) {
                    $Command += " WHERE {0}" -f ($Filters -join ' AND ')
                }

                (Invoke-DSCPullServerSQLCommand @PSBoundParameters -CommandType Get -Script $Command) | ForEach-Object {
                    [DSCNodeStatusReport]::New($_)
                }
            }
        }
    }
}

function Remove-DSCPullServerAdminStatusReport {
    [cmdletbinding(DefaultParameterSetName = "SQL")]
    param (
        [Parameter(Mandatory, ParameterSetName = "ESE")]
        [string]
        $ESEFilePath,

        [Parameter(Mandatory, ParameterSetName = "SQL")]
        [string]
        $SQLServer,

        [Parameter(ParameterSetName = "SQL")]
        [pscredential]
        $SQLCredential,

        [Parameter(ValueFromPipelineByPropertyName, DontShow)]
        [guid]
        $JobId,

        [Parameter()]
        [datetime]
        $FromStartTime,

        [Parameter()]
        [datetime]
        $ToStartTime
    )

    process {
        switch ($PSCmdlet.ParameterSetName) {

            'ESE' {
                Write-Warning "Deleting Status Reports from ESE database using JobID or End Date "
                $Params = @{}
                if ($PSBoundParameters.ContainsKey("FromStartTime")) {
                    $Params.Add("FromStartTime", $FromStartTime)
                }
                if ($PSBoundParameters.ContainsKey("ToStartTime")) {
                    $Params.Add("ToStartTime", $ToStartTime)
                }
                Remove-ESEDSCPullServerAdminReport @Params
            }

            'SQL' {
                $Command = "DELETE FROM RegistrationData {0}"
                $Filters = @()

                if ($PSBoundParameters.ContainsKey("JobId")) {
                    $Filters += "JobId = '$JobId'"
                }

                if ($PSBoundParameters.ContainsKey("FromStartTime")) {
                    $Filters += "StartTime >= '{0}'" -f (Get-Date $FromStartTime -f s)
                }

                if ($PSBoundParameters.ContainsKey("ToStartTime")) {
                    $Filters += "StartTime <= '{0}'" -f (Get-Date $ToStartTime -f s)
                }

                if ($Filters.Count -gt 0) {
                    $Command += " WHERE {0}" -f ($Filters -join ' AND ')
                }

                $Output = Invoke-DSCPullServerSQLCommand @PSBoundParameters -CommandType Set -Script $Command
                Write-Verbose "Agents Deleted: $Output"
            }
        }
    }
}

function Import-DSCPullServerAdminSQLDataFromEDB {
    [cmdletbind()]
    param(
        [Parameter(Mandatory)]
        [string]
        $ESEFilePath,

        [Parameter(Mandatory)]
        [string]
        $SQLServer,

        [Parameter()]
        [pscredential]
        $SQLCredential,

        [Parameter()]
        [ValidateSet("ToSQL","ToESE")]
        [string]
        $Direction = "ToSQL",

        [Parameter()]
        [ValidateSet("Devices", "RegistrationData", "StatusReports")]
        [string[]]
        $ObjectsToMigrate = @("Devices", "RegistrationData")
    )

    process {

        $GetParams = @{}
        $NewParams = @{}
        if($Direction -eq "ToSQL") {
            $GetParams = @{ESEFilePath = $ESEFilePath}
            $NewParams = @{SQLServer = $SQLServer}
            if($PSBoundParameters.ContainsKey("SQLCredential")) {
                $NewParams.Add("SQLCredential", $SQLCredential)
            }
        } else {
            $NewParams = @{ESEFilePath = $ESEFilePath}
            $GetParams = @{SQLServer = $SQLServer}
            if($PSBoundParameters.ContainsKey("SQLCredential")) {
                $GetParams.Add("SQLCredential", $SQLCredential)
            }
        }

        $ObjectsToMigrate | ForEach-Object {
            switch ($_) {
                'Devices' {
                    Get-ESEDSCPullServerAdminDevice @GetParams | New-DSCPullServerAdminDevice @NewParams
                }
                'RegistrationData' {
                    Get-ESEDSCPullServerAdminRegistration @GetParams | New-DSCPullServerAdminRegistration @NewParams
                }
            }
        }
    }
}

function New-DSCPullServerAdminSQLDatabase {
    [cmdletbinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [string]
        $SQLServer,

        [Parameter()]
        [pscredential]
        $SQLCredential,

        [Parameter(Mandatory)]
        [string]
        $DBFolderPath
    )

    begin {
        $Script = Get-Content $PSScriptRoot\SQLScripts\CreateDB.sql -Raw
        $Script = $Script -replace '{0}\', $DBFolderPath.TrimEnd("\")
    }
    process {
        Invoke-DSCPullServerSQLCommand @PSBoundParameters -CommandType Set -Script $Script
    }
}

Export-ModuleMember -Function *-DSCPullServerAdmin*
