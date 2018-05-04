#Import-Module $PSScriptRoot\DSCPullServerAdmin.dll -Prefix ESE

$DSCPullServerConnections = [System.Collections.ArrayList]::new()

#region classes
class DSCDevice {
    [string] $TargetName

    [guid] $ConfigurationID

    [string] $ServerCheckSum

    [string] $TargetCheckSum

    [bool] $NodeCompliant

    [datetime] $LastComplianceTime

    [datetime] $LastHeartbeatTime

    [bool] $Dirty

    [int32] $StatusCode

    DSCDevice ([System.Data.Common.DbDataRecord] $Input) {
        for ($i = 0; $i -lt $Input.FieldCount; $i++) {
            $name = $Input.GetName($i)

            $this."$name" = $Input[$i]
        }
    }
}

class DSCNodeRegistration {
    [Guid] $AgentId

    [string] $LCMVersion

    [string] $NodeName

    [IPAddress[]] $IPAddress

    [string[]] $ConfigurationNames

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
    [Guid] $JobId

    [Guid] $Id

    [string] $OperationType

    [string] $RefreshMode

    [string] $Status

    [string] $LCMVersion

    [string] $ReportFormatVersion

    [string] $ConfigurationVersion

    [string] $NodeName

    [IPAddress[]] $IPAddress

    [datetime] $StartTime

    [datetime] $EndTime

    [PSObject[]] $Errors

    [PSObject[]] $StatusData

    [bool] $RebootRequested

    [PSObject[]] $AdditionalData

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

enum DSCPullServerConnectionType {
    SQL
    ESE
}

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
        if ($this.Credential) {
            return 'Server={0};uid={1};pwd={2};Trusted_Connection=False;Database={3};' -f @(
                $this.SQLServer,
                $this.Credential.UserName,
                $this.Credential.GetNetworkCredential().Password,
                $this.Database
            )
        } else {
            return 'Server={0};Integrated Security=True;Database={1};' -f @(
                $this.SQLServer,
                $this.Database
            )
        }
    }
}

class DSCPullServerESEConnection : DSCPullServerConnection {
    [string] $ESEFilePath

    DSCPullServerESEConnection () : Base ([DSCPullServerConnectionType]::ESE) {
    }

    DSCPullServerESEConnection ([string]$Path) : base([DSCPullServerConnectionType]::ESE) {
        $this.ESEFilePath = $Path
    }
}
#endregion

#region table Get functions
function Get-DSCPullServerAdminDevice {
    [CmdletBinding(DefaultParameterSetName = 'Connection')]
    param (
        [Parameter()]
        [String] $TargetName,
        
        [Parameter(ParameterSetName = 'Connection')]
        [DSCPullServerConnection] $Connection = (Get-DSCPullServerAdminConnection -OnlyShowActive),

        [Parameter(Mandatory, ParameterSetName = 'ESE')]
        [ValidateNotNullOrEmpty()]
        [string] $ESEFilePath,

        [Parameter(Mandatory, ParameterSetName = 'SQL')]
        [ValidateNotNullOrEmpty()]
        [Alias('SQLInstance')]
        [string] $SQLServer,

        [Parameter(ParameterSetName = 'SQL')]
        [pscredential] $Credential,

        [Parameter(ParameterSetName = 'SQL')]
        [string] $Database
    )

    begin {
        if ($null -ne $Connection) {
            [void] $PSBoundParameters.Add('Connection', $Connection)
        }
        $Connection = PreProc -ParameterSetName $PSCmdlet.ParameterSetName @PSBoundParameters
        if ($null -eq $Connection) {
            return
        }
    }
    process {
        switch ($Connection.Type) {
            ESE {
                $eseParams = @{}
                if ($PSBoundParameters.ContainsKey('TargetName')) {
                    $eseParams.Add('TargetName', $TargetName)
                }
                Get-ESEDSCPullServerAdminRegistration @eseParams
            }
            SQL {
                $tsqlScript = 'SELECT * FROM Devices'
                $filters = [System.Collections.ArrayList]::new()
                if ($PSBoundParameters.ContainsKey("TargetName")) {
                    [void] $filters.Add(("TargetName like '{0}'" -f $TargetName.Replace('*','%')))
                }

                if ($filters.Count -ge 1) {
                    $tsqlScript += " WHERE {0}" -f ($filters -join ' AND ')
                }

                Invoke-DSCPullServerSQLCommand -Connection $Connection -Script $tsqlScript | ForEach-Object {
                    [DSCDevice]::New($_)
                }
            }
        }
    }
    end {
        if ($Connection.Type -eq [DSCPullServerConnectionType]::ESE) {
            Dismount-ESEDSCPullServerAdminDatabase
        }
    }
}

function Get-DSCPullServerAdminRegistration {
    [CmdletBinding(DefaultParameterSetName = 'Connection')]
    param (
        [Parameter()]
        [guid] $AgentId,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [Alias('Name')]
        [string] $NodeName,

        [Parameter(ParameterSetName = 'Connection')]
        [DSCPullServerConnection] $Connection = (Get-DSCPullServerAdminConnection -OnlyShowActive),

        [Parameter(Mandatory, ParameterSetName = 'ESE')]
        [ValidateNotNullOrEmpty()]
        [string] $ESEFilePath,

        [Parameter(Mandatory, ParameterSetName = 'SQL')]
        [ValidateNotNullOrEmpty()]
        [Alias('SQLInstance')]
        [string] $SQLServer,

        [Parameter(ParameterSetName = 'SQL')]
        [pscredential] $Credential,

        [Parameter(ParameterSetName = 'SQL')]
        [string] $Database
    )

    begin {
        if ($null -ne $Connection) {
            [void] $PSBoundParameters.Add('Connection', $Connection)
        }
        $Connection = PreProc -ParameterSetName $PSCmdlet.ParameterSetName @PSBoundParameters
        if ($null -eq $Connection) {
            return
        }
    }
    process {
        switch ($Connection.Type) {
            ESE {
                $eseParams = @{}
                if ($PSBoundParameters.ContainsKey('AgentId')) {
                    $eseParams.Add('AgentId', $AgentId)
                }
                if ($PSBoundParameters.ContainsKey("NodeName")) {
                    $eseParams.Add('NodeName', $NodeName)
                }
                Get-ESEDSCPullServerAdminRegistration @eseParams
            }
            SQL {
                $tsqlScript = 'SELECT * FROM RegistrationData'
                $filters = [System.Collections.ArrayList]::new()
                if ($PSBoundParameters.ContainsKey('AgentId')) {
                    [void] $filters.Add(("AgentId = '{0}'" -f $AgentId))
                }
                if ($PSBoundParameters.ContainsKey("NodeName")) {
                    [void] $filters.Add(("NodeName like '{0}'" -f $NodeName.Replace('*','%')))
                }

                if ($filters.Count -ge 1) {
                    $tsqlScript += " WHERE {0}" -f ($filters -join ' AND ')
                }

                Invoke-DSCPullServerSQLCommand -Connection $Connection -Script $tsqlScript | ForEach-Object {
                    [DSCNodeRegistration]::New($_)
                }
            }
        }
    }
    end {
        if ($Connection.Type -eq [DSCPullServerConnectionType]::ESE) {
            Dismount-ESEDSCPullServerAdminDatabase
        }
    }
}

function Get-DSCPullServerAdminStatusReport {
    [CmdletBinding(DefaultParameterSetName = 'Connection')]
    param (
        [Parameter(ValueFromPipelineByPropertyName)]
        [guid]
        $AgentId,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [Alias('Name')]
        [string] $NodeName,

        [Parameter()]
        [datetime]
        $FromStartTime,

        [Parameter()]
        [datetime]
        $ToStartTime,

        [Parameter(ParameterSetName = 'Connection')]
        [DSCPullServerConnection] $Connection = (Get-DSCPullServerAdminConnection -OnlyShowActive),

        [Parameter(Mandatory, ParameterSetName = 'ESE')]
        [ValidateNotNullOrEmpty()]
        [string] $ESEFilePath,

        [Parameter(Mandatory, ParameterSetName = 'SQL')]
        [ValidateNotNullOrEmpty()]
        [Alias('SQLInstance')]
        [string] $SQLServer,

        [Parameter(ParameterSetName = 'SQL')]
        [pscredential] $Credential,

        [Parameter(ParameterSetName = 'SQL')]
        [string] $Database
    )

    begin {
        if ($null -ne $Connection) {
            [void] $PSBoundParameters.Add('Connection', $Connection)
        }
        $Connection = PreProc -ParameterSetName $PSCmdlet.ParameterSetName @PSBoundParameters
        if ($null -eq $Connection) {
            return
        }
    }
    process {
        switch ($Connection.Type) {

            ESE {
                $Params = @{}
                if ($PSBoundParameters.ContainsKey("FromStartTime")) {
                    $Params.Add("FromStartTime", $FromStartTime)
                }
                if ($PSBoundParameters.ContainsKey("ToStartTime")) {
                    $Params.Add("ToStartTime", $ToStartTime)
                }
                Get-ESEDSCPullServerAdminReport -NodeName $NodeName @Params
            }
            SQL {
                $tsqlScript = "SELECT * FROM StatusReport"
                $filters = [System.Collections.ArrayList]::new()
                if ($PSBoundParameters.ContainsKey('AgentId')) {
                    [void] $filters.Add(("AgentId = '{0}'" -f $AgentId))
                }
                if ($PSBoundParameters.ContainsKey("NodeName")) {
                    [void] $filters.Add(("NodeName like '{0}'" -f $NodeName.Replace('*','%')))
                }
                if ($PSBoundParameters.ContainsKey("FromStartTime")) {
                    [void] $filters.Add(("StartTime >= '{0}'" -f (Get-Date $FromStartTime -f s)))
                }

                if ($PSBoundParameters.ContainsKey("ToStartTime")) {
                    [void] $filters.Add(("StartTime <= '{0}'" -f (Get-Date $ToStartTime -f s)))
                }

                if ($filters.Count -ge 1) {
                    $tsqlScript += " WHERE {0}" -f ($filters -join ' AND ')
                }

                Invoke-DSCPullServerSQLCommand -Connection $Connection -Script $tsqlScript | ForEach-Object {
                    [DSCNodeStatusReport]::New($_)
                }
            }
        }
    }
    end {
        if ($Connection.Type -eq [DSCPullServerConnectionType]::ESE) {
            Dismount-ESEDSCPullServerAdminDatabase
        }
    }
}
#endregion

#region table New functions

<#
function New-DSCPullServerAdminRegistration {
    [CmdletBinding(DefaultParameterSetName = "DefaultConnection")]
    param (
        [Parameter(ParameterSetName = "DefaultConnection", DontShow)]
        [DSCPullServerConnection]
        $Connection = $script:DefaultDSCPullServerConnection,

        [Parameter(Mandatory, ParameterSetName = "ESE")]
        [string]
        $ESEFilePath,

        [Parameter(Mandatory, ParameterSetName = "SQL")]
        [string]
        $SQLServer,

        [Parameter(ParameterSetName = "SQL")]
        [pscredential]
        $SQLCredential,

        [Parameter(ParameterSetName = "SQL")]
        [string]
        $Database,

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

    begin {
        if ($PSCmdlet.ParameterSetName -eq 'DefaultConnection' -and
            $false -eq (Test-DefaultDSCPullServerConnection $Connection)) {
            break
        } elseif ($PSCmdlet.ParameterSetName -eq 'DefaultConnection') {
            if ($Connection -is [DSCPullServerESEConnection]) {
                $PSBoundParameters["ESEFilePath"] = $Connection.ESEFilePath
            }

            if ($Connection -is [DSCPullServerSQLConnection]) {
                $PSBoundParameters["SQLServer"] = $Connection.SQLServer
                if ($null -ne $Connection.Credential) {
                    $PSBoundParameters["SQLCredential"] = $Connection.SQLCredential
                }
            }
        } else {
            $Connection = [DSCPullServerConnection]::New($PSCmdlet.ParameterSetName)
        }

        if ($Connection.Type -eq [DSCPullServerConnectionType]::ESE) {
            Mount-ESEDSCPullServerAdminDatabase -ESEPath $PSBoundParameters["ESEFilePath"]
        }
    }

    end {
        if ($Connection.Type -eq [DSCPullServerConnectionType]::ESE) {
            Dismount-ESEDSCPullServerAdminDatabase
        }
    }

    process {
        switch ($Connection.Type) {

            ([DSCPullServerConnectionType]::ESE).ToString() {
                Write-Warning "Add new agent registrations to the ESE database is not currently supported"
            }

            ([DSCPullServerConnectionType]::SQL).ToString() {
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
#>

<#
function New-DSCPullServerAdminDevice {
    [CmdletBinding(DefaultParameterSetName = "DefaultConnection")]
    param (
        [Parameter(ParameterSetName = "DefaultConnection", DontShow)]
        [DSCPullServerConnection]
        $Connection = $script:DefaultDSCPullServerConnection,

        [Parameter(Mandatory, ParameterSetName = "ESE")]
        [string]
        $ESEFilePath,

        [Parameter(Mandatory, ParameterSetName = "SQL")]
        [string]
        $SQLServer,

        [Parameter(ParameterSetName = "SQL")]
        [pscredential]
        $SQLCredential,

        [Parameter(ParameterSetName = "SQL")]
        [string]
        $Database,

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

    begin {
        if ($PSCmdlet.ParameterSetName -eq 'DefaultConnection' -and
            $false -eq (Test-DefaultDSCPullServerConnection $Connection)) {
            break
        } elseif ($PSCmdlet.ParameterSetName -eq 'DefaultConnection') {
            if ($Connection -is [DSCPullServerESEConnection]) {
                $PSBoundParameters["ESEFilePath"] = $Connection.ESEFilePath
            }

            if ($Connection -is [DSCPullServerSQLConnection]) {
                $PSBoundParameters["SQLServer"] = $Connection.SQLServer
                if ($null -ne $Connection.Credential) {
                    $PSBoundParameters["SQLCredential"] = $Connection.SQLCredential
                }
            }
        } else {
            $Connection = [DSCPullServerConnection]::New($PSCmdlet.ParameterSetName)
        }

        if ($Connection.Type -eq [DSCPullServerConnectionType]::ESE) {
            Mount-ESEDSCPullServerAdminDatabase -ESEPath $PSBoundParameters["ESEFilePath"]
        }
    }

    end {
        if ($Connection.Type -eq [DSCPullServerConnectionType]::ESE) {
            Dismount-ESEDSCPullServerAdminDatabase
        }
    }

    process {
        switch ($Connection.Type) {

            ([DSCPullServerConnectionType]::ESE).ToString() {
                Write-Warning "Add new agent registrations to the ESE database is not currently supported"
            }

            ([DSCPullServerConnectionType]::SQL).ToString() {
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
#>

<#
function New-DSCPullServerAdminStatusReport {

}
#>
#endregion

#region table Set functions

<#
function Set-DSCPullServerAdminRegistration {
    [CmdletBinding(DefaultParameterSetName = "DefaultConnection")]
    param (
        [Parameter(ParameterSetName = "DefaultConnection", DontShow)]
        [DSCPullServerConnection]
        $Connection = $script:DefaultDSCPullServerConnection,

        [Parameter(Mandatory, ParameterSetName = "ESE")]
        [string]
        $ESEFilePath,

        [Parameter(Mandatory, ParameterSetName = "SQL")]
        [string]
        $SQLServer,

        [Parameter(ParameterSetName = "SQL")]
        [pscredential]
        $SQLCredential,

        [Parameter(ParameterSetName = "SQL")]
        [string]
        $Database,

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

    begin {
        if ($PSCmdlet.ParameterSetName -eq 'DefaultConnection' -and
            $false -eq (Test-DefaultDSCPullServerConnection $Connection)) {
            break
        } elseif ($PSCmdlet.ParameterSetName -eq 'DefaultConnection') {
            if ($Connection -is [DSCPullServerESEConnection]) {
                $PSBoundParameters["ESEFilePath"] = $Connection.ESEFilePath
            }

            if ($Connection -is [DSCPullServerSQLConnection]) {
                $PSBoundParameters["SQLServer"] = $Connection.SQLServer
                if ($null -ne $Connection.Credential) {
                    $PSBoundParameters["SQLCredential"] = $Connection.SQLCredential
                }
            }
        } else {
            $Connection = [DSCPullServerConnection]::New($PSCmdlet.ParameterSetName)
        }

        if ($Connection.Type -eq [DSCPullServerConnectionType]::ESE) {
            Mount-ESEDSCPullServerAdminDatabase -ESEPath $PSBoundParameters["ESEFilePath"]
        }
    }

    end {
        if ($Connection.Type -eq [DSCPullServerConnectionType]::ESE) {
            Dismount-ESEDSCPullServerAdminDatabase
        }
    }

    process {
        switch ($Connection.Type) {

            ([DSCPullServerConnectionType]::ESE).ToString() {
                Write-Warning "Only updating agent configuration names in the ESE database is currently supported"

                Set-ESEDSCPullServerAdminRegistration -AgentId $AgentId -ConfigurationName $ConfigurationNames
            }

            ([DSCPullServerConnectionType]::SQL).ToString() {
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
#>

<#
function Set-DSCPullServerAdminDevice {
    [CmdletBinding(DefaultParameterSetName = "DefaultConnection")]
    param (
        [Parameter(ParameterSetName = "DefaultConnection", DontShow)]
        [DSCPullServerConnection]
        $Connection = $script:DefaultDSCPullServerConnection,

        [Parameter(Mandatory, ParameterSetName = "ESE")]
        [string]
        $ESEFilePath,

        [Parameter(Mandatory, ParameterSetName = "SQL")]
        [string]
        $SQLServer,

        [Parameter(ParameterSetName = "SQL")]
        [pscredential]
        $SQLCredential,

        [Parameter(ParameterSetName = "SQL")]
        [string]
        $Database,

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

    begin {
        if ($PSCmdlet.ParameterSetName -eq 'DefaultConnection' -and
            $false -eq (Test-DefaultDSCPullServerConnection $Connection)) {
            break
        } elseif ($PSCmdlet.ParameterSetName -eq 'DefaultConnection') {
            if ($Connection -is [DSCPullServerESEConnection]) {
                $PSBoundParameters["ESEFilePath"] = $Connection.ESEFilePath
            }

            if ($Connection -is [DSCPullServerSQLConnection]) {
                $PSBoundParameters["SQLServer"] = $Connection.SQLServer
                if ($null -ne $Connection.Credential) {
                    $PSBoundParameters["SQLCredential"] = $Connection.SQLCredential
                }
            }
        } else {
            $Connection = [DSCPullServerConnection]::New($PSCmdlet.ParameterSetName)
        }

        if ($Connection.Type -eq [DSCPullServerConnectionType]::ESE) {
            Mount-ESEDSCPullServerAdminDatabase -ESEPath $PSBoundParameters["ESEFilePath"]
        }
    }

    end {
        if ($Connection.Type -eq [DSCPullServerConnectionType]::ESE) {
            Dismount-ESEDSCPullServerAdminDatabase
        }
    }

    process {
        switch ($Connection.Type) {

            ([DSCPullServerConnectionType]::ESE).ToString() {
                Write-Warning "Updating version 1 agents in the ESE database is not currently supported"
            }

            ([DSCPullServerConnectionType]::SQL).ToString() {
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
#>

<#
function Set-DSCPullServerAdminStatusReport {

}
#>
#endregion

#region table Remove functions
<#
function Remove-DSCPullServerAdminRegistration {
    [CmdletBinding(DefaultParameterSetName = "DefaultConnection")]
    param (
        [Parameter(ParameterSetName = "DefaultConnection", DontShow)]
        [DSCPullServerConnection]
        $Connection = $script:DefaultDSCPullServerConnection,

        [Parameter(Mandatory, ParameterSetName = "ESE")]
        [string]
        $ESEFilePath,

        [Parameter(Mandatory, ParameterSetName = "SQL")]
        [string]
        $SQLServer,

        [Parameter(ParameterSetName = "SQL")]
        [pscredential]
        $SQLCredential,

        [Parameter(ParameterSetName = "SQL")]
        [string]
        $Database,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [guid]
        $AgentId
    )

    begin {
        if ($PSCmdlet.ParameterSetName -eq 'DefaultConnection' -and
            $false -eq (Test-DefaultDSCPullServerConnection $Connection)) {
            break
        } elseif ($PSCmdlet.ParameterSetName -eq 'DefaultConnection') {
            if ($Connection -is [DSCPullServerESEConnection]) {
                $PSBoundParameters["ESEFilePath"] = $Connection.ESEFilePath
            }

            if ($Connection -is [DSCPullServerSQLConnection]) {
                $PSBoundParameters["SQLServer"] = $Connection.SQLServer
                if ($null -ne $Connection.Credential) {
                    $PSBoundParameters["SQLCredential"] = $Connection.SQLCredential
                }
            }
        } else {
            $Connection = [DSCPullServerConnection]::New($PSCmdlet.ParameterSetName)
        }

        if ($Connection.Type -eq [DSCPullServerConnectionType]::ESE) {
            Mount-ESEDSCPullServerAdminDatabase -ESEPath $PSBoundParameters["ESEFilePath"]
        }
    }

    end {
        if ($Connection.Type -eq [DSCPullServerConnectionType]::ESE) {
            Dismount-ESEDSCPullServerAdminDatabase
        }
    }

    process {
        switch ($Connection.Type) {

            ([DSCPullServerConnectionType]::ESE).ToString() {
                Remove-ESEDSCPullServerAdminRegistration -AgentId $AgentId
            }

            ([DSCPullServerConnectionType]::SQL).ToString() {
                $Command = "DELETE FROM RegistrationData WHERE AgentId = '$AgentId'"

                $Output = Invoke-DSCPullServerSQLCommand @PSBoundParameters -CommandType Set -Script $Command
                Write-Verbose "Agents Deleted: $Output"
            }
        }
    }
}
#>

<#
function Remove-DSCPullServerAdminDevice {
    [CmdletBinding(DefaultParameterSetName = "DefaultConnection")]
    param (
        [Parameter(ParameterSetName = "DefaultConnection", DontShow)]
        [DSCPullServerConnection]
        $Connection = $script:DefaultDSCPullServerConnection,

        [Parameter(Mandatory, ParameterSetName = "ESE")]
        [string]
        $ESEFilePath,

        [Parameter(Mandatory, ParameterSetName = "SQL")]
        [string]
        $SQLServer,

        [Parameter(ParameterSetName = "SQL")]
        [pscredential]
        $SQLCredential,

        [Parameter(ParameterSetName = "SQL")]
        [string]
        $Database,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [string]
        $TargetName
    )

    begin {
        if ($PSCmdlet.ParameterSetName -eq 'DefaultConnection' -and
            $false -eq (Test-DefaultDSCPullServerConnection $Connection)) {
            break
        } elseif ($PSCmdlet.ParameterSetName -eq 'DefaultConnection') {
            if ($Connection -is [DSCPullServerESEConnection]) {
                $PSBoundParameters["ESEFilePath"] = $Connection.ESEFilePath
            }

            if ($Connection -is [DSCPullServerSQLConnection]) {
                $PSBoundParameters["SQLServer"] = $Connection.SQLServer
                if ($null -ne $Connection.Credential) {
                    $PSBoundParameters["SQLCredential"] = $Connection.SQLCredential
                }
            }
        } else {
            $Connection = [DSCPullServerConnection]::New($PSCmdlet.ParameterSetName)
        }

        if ($Connection.Type -eq [DSCPullServerConnectionType]::ESE) {
            Mount-ESEDSCPullServerAdminDatabase -ESEPath $PSBoundParameters["ESEFilePath"]
        }
    }

    end {
        if ($Connection.Type -eq [DSCPullServerConnectionType]::ESE) {
            Dismount-ESEDSCPullServerAdminDatabase
        }
    }

    process {
        switch ($Connection.Type) {

            ([DSCPullServerConnectionType]::ESE).ToString() {
                Write-Warning "Removing version 1 agents in the ESE database is not currently supported"
            }

            ([DSCPullServerConnectionType]::SQL).ToString() {
                $Command = "DELETE FROM Devices WHERE TargetName = '$TargetName'"

                $Output = Invoke-DSCPullServerSQLCommand @PSBoundParameters -CommandType Set -Script $Command
                Write-Verbose "Agents Deleted: $Output"
            }
        }
    }
}
#>

<#
function Remove-DSCPullServerAdminStatusReport {
    [CmdletBinding(DefaultParameterSetName = "DefaultConnection")]
    param (
        [Parameter(ParameterSetName = "DefaultConnection", DontShow)]
        [DSCPullServerConnection]
        $Connection = $script:DefaultDSCPullServerConnection,

        [Parameter(Mandatory, ParameterSetName = "ESE")]
        [string]
        $ESEFilePath,

        [Parameter(Mandatory, ParameterSetName = "SQL")]
        [string]
        $SQLServer,

        [Parameter(ParameterSetName = "SQL")]
        [pscredential]
        $SQLCredential,

        [Parameter(ParameterSetName = "SQL")]
        [string]
        $Database,

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

    begin {
        if ($PSCmdlet.ParameterSetName -eq 'DefaultConnection' -and
            $false -eq (Test-DefaultDSCPullServerConnection $Connection)) {
            break
        } elseif ($PSCmdlet.ParameterSetName -eq 'DefaultConnection') {
            if ($Connection -is [DSCPullServerESEConnection]) {
                $PSBoundParameters["ESEFilePath"] = $Connection.ESEFilePath
            }

            if ($Connection -is [DSCPullServerSQLConnection]) {
                $PSBoundParameters["SQLServer"] = $Connection.SQLServer
                if ($null -ne $Connection.Credential) {
                    $PSBoundParameters["SQLCredential"] = $Connection.SQLCredential
                }
            }
        } else {
            $Connection = [DSCPullServerConnection]::New($PSCmdlet.ParameterSetName)
        }

        if ($Connection.Type -eq [DSCPullServerConnectionType]::ESE) {
            Mount-ESEDSCPullServerAdminDatabase -ESEPath $PSBoundParameters["ESEFilePath"]
        }
    }

    end {
        if ($Connection.Type -eq [DSCPullServerConnectionType]::ESE) {
            Dismount-ESEDSCPullServerAdminDatabase
        }
    }

    process {
        switch ($Connection.Type) {

            ([DSCPullServerConnectionType]::ESE).ToString() {
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

            ([DSCPullServerConnectionType]::SQL).ToString() {
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
#>
#endregion

#region database functions
<#
function Import-DSCPullServerAdminData {
    [CmdletBinding()]
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
        [string]
        $Database,

        [Parameter()]
        [ValidateSet("ToSQL", "ToESE")]
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
        if ($Direction -eq "ToSQL") {
            $GetParams = @{ESEFilePath = $ESEFilePath}
            $NewParams = @{SQLServer = $SQLServer}
            if ($PSBoundParameters.ContainsKey("SQLCredential")) {
                $NewParams.Add("SQLCredential", $SQLCredential)
            }
            if ($PSBoundParameters.ContainsKey("Database")) {
                $NewParams.Add("Database", $Database)
            }
        } else {
            $NewParams = @{ESEFilePath = $ESEFilePath}
            $GetParams = @{SQLServer = $SQLServer}
            if ($PSBoundParameters.ContainsKey("SQLCredential")) {
                $GetParams.Add("SQLCredential", $SQLCredential)
            }
            if ($PSBoundParameters.ContainsKey("Database")) {
                $GetParams.Add("Database", $Database)
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
#>

<#
function New-DSCPullServerAdminSQLDatabase {
    [CmdletBinding()]
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
#>
#endregion

#region connection functions
function New-DSCPullServerAdminConnection {
    [CmdletBinding(DefaultParameterSetName = 'SQL')]
    param (
        [Parameter(Mandatory, ParameterSetName = 'ESE')]
        [ValidateNotNullOrEmpty()]
        [string] $ESEFilePath,

        [Parameter(ParameterSetName = 'SQL')]
        [ValidateNotNullOrEmpty()]
        [Alias('SQLInstance')]
        [string] $SQLServer,

        [Parameter(ParameterSetName = 'SQL')]
        [pscredential] $Credential,

        [Parameter(ParameterSetName = 'SQL')]
        [ValidateNotNullOrEmpty()]
        [string] $Database,

        [switch] $DontStore
    )

    if ($PSCmdlet.ParameterSetName -eq 'SQL') {
        if ($PSBoundParameters.ContainsKey('Credential') -and $PSBoundParameters.ContainsKey('Database')) {
            $connection = [DSCPullServerSQLConnection]::New($SQLServer, $Credential, $Database)
        } elseif ($PSBoundParameters.ContainsKey('Database')) {
            $connection = [DSCPullServerSQLConnection]::New($SQLServer, $Database)
        } elseif ($PSBoundParameters.ContainsKey('Credential')) {
            $connection = [DSCPullServerSQLConnection]::New($SQLServer, $Credential)
        } else {
            $connection = [DSCPullServerSQLConnection]::New($SQLServer)
        }

        # TODO: Precheck if connection is actually working or else fail

        $currentConnections = Get-DSCPullServerAdminConnection -Type 'SQL'
        if ($null -eq $currentConnections) {
            $connection.Index = 0
            $connection.Active = $true
        } else {
            # TODO: Deal with duplicates
            $lastIndex = $currentConnections |
                Sort-Object -Property Index -Descending |
                    Select-Object -First 1 -ExpandProperty Index
            $connection.Index = $lastIndex + 1
            $connection.Active = $false
        }
    } else {
        # TODO: Handle ESE same as SQL
        $connection = [DSCPullServerESEConnection]::New($ESEFilePath)
    }

    if (-not $DontStore) {
        [void] $script:DSCPullServerConnections.Add($connection)
    }
    $connection
}

function Get-DSCPullServerAdminConnection {
    [CmdletBinding()]
    param (
        [Parameter()]
        [DSCPullServerConnectionType] $Type,

        [switch] $OnlyShowActive,

        [Parameter()]
        [uint16] $Index
    )
    if ($PSBoundParameters.ContainsKey('Type')) {
        $result = $script:DSCPullServerConnections | Where-Object -FilterScript {
            $_.Type -eq $Type
        }
    } else {
        $result = $script:DSCPullServerConnections
    }

    if ($PSBoundParameters.ContainsKey('Index')) {
        $result = $result | Where-Object -FilterScript {
            $_.Index -eq $Index
        }
    }

    if ($OnlyShowActive) {
        $result | Where-Object -FilterScript {
            $_.Active
        }
    } else {
        $result
    }
}

function Set-DSCPullServerAdminConnectionActive {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [DSCPullServerConnection] $Connection
    )
    $currentActive = Get-DSCPullServerAdminConnection -OnlyShowActive
    $currentActive.Active = $false
    $Connection.Active = $true
}

function Remove-DSCPullServerAdminConnection {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [DSCPullServerConnection] $Connection
    )
    if ($Connection.Active) {
        Write-Warning -Message 'Removing Current Active Connection, please select or add a new one'
    }
    for ($i = 0; $i -lt $script:DSCPullServerConnections.Count; $i++) {
        if ($script:DSCPullServerConnections[$i].Equals($Connection)) {
            $script:DSCPullServerConnections.RemoveAt($i)
        }
    }
}
#endregion


#region private functions
function Invoke-DSCPullServerSQLCommand {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [DSCPullServerSQLConnection] $Connection,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string] $Script,

        [Parameter()]
        [ValidateSet('Get', 'Set')]
        [string] $CommandType = 'Get',

        [Parameter(ValueFromRemainingArguments, DontShow)]
        $DroppedParams
    )

    begin {
        $sqlConnection = [System.Data.SqlClient.SqlConnection]::new($Connection.ConnectionString())
        try {
            $sqlConnection.Open()
        } catch {
            Write-Error -ErrorRecord $_ -ErrorAction Stop
        }
    }
    process {
        try {
            $command = $sqlConnection.CreateCommand()
            $command.CommandText = $Script

            Write-Verbose ("Invoking command: {0}" -f $Script)

            if ($CommandType -eq 'Get') {
                $command.ExecuteReader()
            } else {
                [void] $command.ExecuteNonQuery()
            }
        } catch {
            Write-Error -ErrorRecord $_ -ErrorAction Stop
        } finally {
            if ($false -eq $?) {
                $sqlConnection.Close()
                $sqlConnection.Dispose()
            }
        }
    }
    end {
        $sqlConnection.Close()
        $sqlConnection.Dispose()
    }
}

function Test-DefaultDSCPullServerConnection {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [AllowNull()]
        [DSCPullServerConnection] $Connection
    )

    if ($null -eq $Connection) {
        Write-Warning 'No active connection was found'
        $false
    } else {
        $true
    }
}

function PreProc {
    param (
        [Parameter(Mandatory)]
        [ValidateSet('Connection', 'SQL', 'ESE')]
        [string] $ParameterSetName,

        [DSCPullServerConnection] $Connection,

        [string] $SQLServer,

        [pscredential] $Credential,

        [string] $Database,

        [string] $ESEFilePath,

        [Parameter(ValueFromRemainingArguments)]
        $DroppedParams
    )

    switch ($ParameterSetName) {
        Connection {
            if (Test-DefaultDSCPullServerConnection $Connection) {
                return $Connection
            }
        }
        SQL {
            $newSQLArgs = @{
                SQLServer = $SQLServer
                DontStore = $true
            }

            $PSBoundParameters.Keys | ForEach-Object -Process {
                if ($_ -in 'Credential', 'Database') {
                    [void] $newSQLArgs.Add($_, $PSBoundParameters[$_])
                }
            }
            New-DSCPullServerAdminConnection @newSQLArgs
        }
        ESE {
            #Mount-ESEDSCPullServerAdminDatabase -ESEPath $PSBoundParameters.ESEFilePath
        }
    }
}
#endregion

Export-ModuleMember -Function *-DSCPullServerAdmin*, *-DefaultDSCPullServerConnection
