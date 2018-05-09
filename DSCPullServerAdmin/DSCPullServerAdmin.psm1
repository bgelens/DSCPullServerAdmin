Add-Type -Path "C:\Windows\Microsoft.NET\assembly\GAC_MSIL\microsoft.isam.esent.interop\*\Microsoft.Isam.Esent.Interop.dll"

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

    DSCDevice () {}

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
                    "$($_.Name) = '[`"{0}`"]'" -f ($this."$($_.Name)" -join '","')
                } elseif ($_.Name -eq 'IPAddress') {
                    "$($_.Name) = '{0}'" -f ($this."$($_.Name)" -join ';')
                } else {
                    "$($_.Name) = '{0}'" -f $this."$($_.Name)"
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
                    "'[`"{0}`"]'" -f ($this."$($_.Name)" -join '","')
                } elseif ($_.Name -eq 'IPAddress') {
                    "'{0}'" -f ($this."$($_.Name)" -join ';')
                } else {
                    "'{0}'" -f $this."$($_.Name)"
                }
            } -join ',')
        ))
        return $query
    }

    [string] GetSQLDelete () {
        return ("DELETE FROM RegistrationData WHERE AgentId = '{0}'" -f $this.AgentId)
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

    [datetime] $LastModifiedTime

    [PSObject[]] $Errors

    [PSObject[]] $StatusData

    [bool] $RebootRequested

    [PSObject[]] $AdditionalData

    DSCNodeStatusReport () {}

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
    hidden [object] $Instance
    hidden [object] $SessionId
    hidden [object] $DbId

    DSCPullServerESEConnection () : base([DSCPullServerConnectionType]::ESE) { }

    DSCPullServerESEConnection ([string]$Path) : base([DSCPullServerConnectionType]::ESE) {
        $this.ESEFilePath = (Resolve-Path $Path).ProviderPath
    }
}
#endregion

#region table Get functions
function Get-DSCPullServerAdminDevice {
    [CmdletBinding(DefaultParameterSetName = 'Connection')]
    param (
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [String] $TargetName,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [guid] $ConfigurationID,
        
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
        [ValidateNotNullOrEmpty()]
        [string] $Database
    )

    begin {
        if ($null -ne $Connection -and -not $PSBoundParameters.ContainsKey('Connection')) {
            [void] $PSBoundParameters.Add('Connection', $Connection)
        }
        $Connection = PreProc -ParameterSetName $PSCmdlet.ParameterSetName @PSBoundParameters
        if ($null -eq $Connection) {
            break
        }
    }
    process {
        switch ($Connection.Type) {
            ESE {
                $eseParams = @{
                    Connection = $Connection
                }
                if ($PSBoundParameters.ContainsKey('TargetName')) {
                    $eseParams.Add('TargetName', $TargetName)
                }
                if ($PSBoundParameters.ContainsKey('ConfigurationID')) {
                    $eseParams.Add('ConfigurationID', $ConfigurationID)
                }

                Get-DSCPullServerESEDevice @eseParams
            }
            SQL {
                $tsqlScript = 'SELECT * FROM Devices'
                $filters = [System.Collections.ArrayList]::new()
                if ($PSBoundParameters.ContainsKey("TargetName")) {
                    [void] $filters.Add(("TargetName like '{0}'" -f $TargetName.Replace('*', '%')))
                }
                if ($PSBoundParameters.ContainsKey("ConfigurationID")) {
                    [void] $filters.Add(("ConfigurationID = '{0}'" -f $ConfigurationID))
                }

                if ($filters.Count -ge 1) {
                    $tsqlScript += " WHERE {0}" -f ($filters -join ' AND ')
                }

                Invoke-DSCPullServerSQLCommand -Connection $Connection -Script $tsqlScript | ForEach-Object {
                    try {
                        [DSCDevice]::New($_)
                    } catch {
                        Write-Error -ErrorRecord $_ -ErrorAction Continue
                    }
                }
            }
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
        [ValidateNotNullOrEmpty()]
        [string] $Database
    )

    begin {
        if ($null -ne $Connection -and -not $PSBoundParameters.ContainsKey('Connection')) {
            [void] $PSBoundParameters.Add('Connection', $Connection)
        }
        $Connection = PreProc -ParameterSetName $PSCmdlet.ParameterSetName @PSBoundParameters
        if ($null -eq $Connection) {
            break
        }
    }
    process {
        switch ($Connection.Type) {
            ESE {
                $eseParams = @{
                    Connection = $Connection
                }
                if ($PSBoundParameters.ContainsKey('AgentId')) {
                    $eseParams.Add('AgentId', $AgentId)
                }
                if ($PSBoundParameters.ContainsKey("NodeName")) {
                    $eseParams.Add('NodeName', $NodeName)
                }

                Get-DSCPullServerESERegistration @eseParams
            }
            SQL {
                $tsqlScript = 'SELECT * FROM RegistrationData'
                $filters = [System.Collections.ArrayList]::new()
                if ($PSBoundParameters.ContainsKey('AgentId')) {
                    [void] $filters.Add(("AgentId = '{0}'" -f $AgentId))
                }
                if ($PSBoundParameters.ContainsKey("NodeName")) {
                    [void] $filters.Add(("NodeName like '{0}'" -f $NodeName.Replace('*', '%')))
                }

                if ($filters.Count -ge 1) {
                    $tsqlScript += " WHERE {0}" -f ($filters -join ' AND ')
                }

                Invoke-DSCPullServerSQLCommand -Connection $Connection -Script $tsqlScript | ForEach-Object {
                    try {
                        [DSCNodeRegistration]::New($_)
                    } catch {
                        Write-Error -ErrorRecord $_ -ErrorAction Continue
                    }
                }
            }
        }
    }
}

function Get-DSCPullServerAdminStatusReport {
    [CmdletBinding(DefaultParameterSetName = 'Connection')]
    param (
        # Disabled pipeline binding because ese single session issue    
        [Parameter(<#ValueFromPipelineByPropertyName#>)]
        [guid] $AgentId,

        # Disabled pipeline binding because ese single session issue
        [Parameter(<#ValueFromPipelineByPropertyName#>)]
        [ValidateNotNullOrEmpty()]
        [Alias('Name')]
        [string] $NodeName,

        [Parameter()]
        [datetime] $FromStartTime,

        [Parameter()]
        [datetime] $ToStartTime,

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
        [ValidateNotNullOrEmpty()]
        [string] $Database
    )

    begin {
        if ($null -ne $Connection -and -not $PSBoundParameters.ContainsKey('Connection')) {
            [void] $PSBoundParameters.Add('Connection', $Connection)
        }
        $Connection = PreProc -ParameterSetName $PSCmdlet.ParameterSetName @PSBoundParameters
        if ($null -eq $Connection) {
            break
        }
    }
    process {
        switch ($Connection.Type) {
            ESE {
                $eseParams = @{
                    Connection = $Connection
                }
                if ($PSBoundParameters.ContainsKey('AgentId')) {
                    $eseParams.Add('AgentId', $AgentId)
                }
                if ($PSBoundParameters.ContainsKey('NodeName')) {
                    $eseParams.Add('NodeName', $NodeName)
                }
                if ($PSBoundParameters.ContainsKey('FromStartTime')) {
                    $Params.Add('FromStartTime', $FromStartTime)
                }
                if ($PSBoundParameters.ContainsKey("ToStartTime")) {
                    $Params.Add('ToStartTime', $ToStartTime)
                }

                Get-DSCPullServerESEStatusReport @eseParams
            }
            SQL {
                $tsqlScript = "SELECT * FROM StatusReport"
                $filters = [System.Collections.ArrayList]::new()
                if ($PSBoundParameters.ContainsKey('AgentId')) {
                    [void] $filters.Add(("Id = '{0}'" -f $AgentId))
                }
                if ($PSBoundParameters.ContainsKey("NodeName")) {
                    [void] $filters.Add(("NodeName like '{0}'" -f $NodeName.Replace('*', '%')))
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
                    try {
                        [DSCNodeStatusReport]::New($_)
                    } catch {
                        Write-Error -ErrorRecord $_ -ErrorAction Continue
                    }
                }
            }
        }
    }
}
#endregion

#region table New functions
function New-DSCPullServerAdminRegistration {
    [CmdletBinding(
        DefaultParameterSetName = 'Connection',
        ConfirmImpact = 'Medium',
        SupportsShouldProcess
    )]
    param (
        [Parameter(ValueFromPipelineByPropertyName)]
        [guid] $AgentId,

        [Parameter()]
        [ValidateSet('2.0')]
        [string] $LCMVersion = '2.0',

        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [string] $NodeName,

        [Parameter(ValueFromPipelineByPropertyName)]
        [IPAddress[]] $IPAddress,

        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [string[]] $ConfigurationNames,

        [Parameter(ParameterSetName = 'Connection')]
        [DSCPullServerSQLConnection] $Connection = (Get-DSCPullServerAdminConnection -OnlyShowActive -Type SQL),

        [Parameter(Mandatory, ParameterSetName = 'SQL')]
        [ValidateNotNullOrEmpty()]
        [Alias('SQLInstance')]
        [string] $SQLServer,

        [Parameter(ParameterSetName = 'SQL')]
        [pscredential] $Credential,

        [Parameter(ParameterSetName = 'SQL')]
        [string] $Database,

        [switch] $Force
    )

    begin {
        if ($null -ne $Connection -and -not $PSBoundParameters.ContainsKey('Connection')) {
            [void] $PSBoundParameters.Add('Connection', $Connection)
        }
        $Connection = PreProc -ParameterSetName $PSCmdlet.ParameterSetName @PSBoundParameters
        if ($null -eq $Connection) {
            break
        }
        if (-not $PSBoundParameters.ContainsKey('LCMVersion')) {
            $PSBoundParameters.Add('LCMVersion', $LCMVersion)
        }
    }
    process {
        $nodeRegistration = [DSCNodeRegistration]::new()
        $PSBoundParameters.Keys.Where{
            $_ -in ($nodeRegistration | Get-Member -MemberType Property).Name
        }.ForEach{
            $nodeRegistration.$_ = $PSBoundParameters.$_
        }

        $existingRegistration = Get-DSCPullServerAdminRegistration -Connection $Connection -AgentId $nodeRegistration.AgentId
        if ($null -ne $existingRegistration -and -not $Force) {
            throw "A NodeRegistration with AgentId '$AgentId' already exists. Use -Force to overwrite"
        } elseif ($null -ne $existingRegistration -and $Force) {
            Write-Warning -Message "A NodeRegistration with AgentId '$AgentId' already exists but will be overwritten because the -Force switch is active"
            $tsqlScript = $nodeRegistration.GetSQLUpdate()
        } else {
            $tsqlScript = $nodeRegistration.GetSQLInsert()
        }

        if ($PSCmdlet.ShouldProcess("$($Connection.SQLServer)\$($Connection.Database)", $tsqlScript)) {
            Invoke-DSCPullServerSQLCommand -Connection $Connection -CommandType Set -Script $tsqlScript
        }
    }
}

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
function Set-DSCPullServerAdminRegistration {
    [CmdletBinding(
        DefaultParameterSetName = 'Connection',
        ConfirmImpact = 'Medium',
        SupportsShouldProcess
    )]
    param (
        [Parameter(ValueFromPipelineByPropertyName)]
        [guid] $AgentId,

        [Parameter()]
        [ValidateSet('2.0')]
        [string] $LCMVersion = '2.0',

        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [string] $NodeName,

        [Parameter(ValueFromPipelineByPropertyName)]
        [IPAddress[]] $IPAddress,

        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [string[]] $ConfigurationNames,

        [Parameter(ParameterSetName = 'Connection')]
        [DSCPullServerSQLConnection] $Connection = (Get-DSCPullServerAdminConnection -OnlyShowActive -Type SQL),

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
        if ($null -ne $Connection -and -not $PSBoundParameters.ContainsKey('Connection')) {
            [void] $PSBoundParameters.Add('Connection', $Connection)
        }
        $Connection = PreProc -ParameterSetName $PSCmdlet.ParameterSetName @PSBoundParameters
        if ($null -eq $Connection) {
            break
        }
        if (-not $PSBoundParameters.ContainsKey('LCMVersion')) {
            $PSBoundParameters.Add('LCMVersion', $LCMVersion)
        }
    }
    process {
        $nodeRegistration = [DSCNodeRegistration]::new()
        $PSBoundParameters.Keys.Where{
            $_ -in ($nodeRegistration | Get-Member -MemberType Property).Name
        }.ForEach{
            $nodeRegistration.$_ = $PSBoundParameters.$_
        }

        $existingRegistration = Get-DSCPullServerAdminRegistration -Connection $Connection -AgentId $nodeRegistration.AgentId
        if ($null -eq $existingRegistration) {
            throw "A NodeRegistration with AgentId '$AgentId' was not found"
        } else {
            $tsqlScript = $nodeRegistration.GetSQLUpdate()
        }

        if ($PSCmdlet.ShouldProcess("$($Connection.SQLServer)\$($Connection.Database)", $tsqlScript)) {
            Invoke-DSCPullServerSQLCommand -Connection $Connection -CommandType Set -Script $tsqlScript
        }
    }
}

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
function Remove-DSCPullServerAdminRegistration {
    [CmdletBinding(
        DefaultParameterSetName = 'Connection',
        ConfirmImpact = 'High',
        SupportsShouldProcess
    )]
    param (
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [guid] $AgentId,

        [Parameter(ParameterSetName = 'Connection')]
        [DSCPullServerSQLConnection] $Connection = (Get-DSCPullServerAdminConnection -OnlyShowActive -Type SQL),

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
        if ($null -ne $Connection -and -not $PSBoundParameters.ContainsKey('Connection')) {
            [void] $PSBoundParameters.Add('Connection', $Connection)
        }
        $Connection = PreProc -ParameterSetName $PSCmdlet.ParameterSetName @PSBoundParameters
        if ($null -eq $Connection) {
            break
        }
    }
    process {
        $existingRegistration = Get-DSCPullServerAdminRegistration -Connection $Connection -AgentId $AgentId
        if ($null -eq $existingRegistration) {
            Write-Warning -Message "A NodeRegistration with AgentId '$AgentId' was not found"
        } else {
            $tsqlScript = $existingRegistration.GetSQLDelete()
            if ($PSCmdlet.ShouldProcess("$($Connection.SQLServer)\$($Connection.Database)", $tsqlScript)) {
                Invoke-DSCPullServerSQLCommand -Connection $Connection -CommandType Set -Script $tsqlScript
            }
        }
    }
}

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

    $currentConnections = Get-DSCPullServerAdminConnection
    $lastIndex = $currentConnections |
        Sort-Object -Property Index -Descending |
        Select-Object -First 1 -ExpandProperty Index

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
    } else {
        # TODO: Handle ESE same as SQL
        $connection = [DSCPullServerESEConnection]::New($ESEFilePath)
    }

    if (-not $DontStore) {
        if ($null -eq $currentConnections) {
            $connection.Index = 0
            $connection.Active = $true
        } else {
            $connection.Index = $lastIndex + 1
            $connection.Active = $false
        }
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
    if ($null -ne $currentActive) {
        $currentActive.Active = $false
    }
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

function Mount-DSCPullServerESEDatabase {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [DSCPullServerESEConnection] $Connection,

        [ValidateSet('None', 'ReadOnly', 'Exclusive')]
        [string] $Mode = 'None'
    )

    $instanceName = [guid]::NewGuid().guid
    $systemPath = (Split-Path -Path $Connection.ESEFilePath) + '\'

    [Microsoft.Isam.Esent.Interop.JET_INSTANCE] $jetInstance = [Microsoft.Isam.Esent.Interop.JET_INSTANCE]::Nil
    [Microsoft.Isam.Esent.Interop.JET_SESID] $sessionId = [Microsoft.Isam.Esent.Interop.JET_SESID]::Nil
    [Microsoft.Isam.Esent.Interop.JET_DBID] $dbId = [Microsoft.Isam.Esent.Interop.JET_DBID]::Nil

    #parameter options:
    #https://msdn.microsoft.com/en-us/library/microsoft.isam.esent.interop.jet_param(v=exchg.10).aspx

    'NoInformationEvent', 'CircularLog' | ForEach-Object -Process {
        [void] [Microsoft.Isam.Esent.Interop.Api]::JetSetSystemParameter(
            $jetInstance,
            [Microsoft.Isam.Esent.Interop.JET_SESID]::Nil,
            [Microsoft.Isam.Esent.Interop.JET_param]$_,
            1,
            $null
        )
    }

    [void] [Microsoft.Isam.Esent.Interop.Api]::JetSetSystemParameter(
        $jetInstance,
        [Microsoft.Isam.Esent.Interop.JET_SESID]::Nil,
        [Microsoft.Isam.Esent.Interop.JET_param]::LogFileSize,
        128,
        $null
    )

    [void] [Microsoft.Isam.Esent.Interop.Api]::JetSetSystemParameter(
        $jetInstance,
        [Microsoft.Isam.Esent.Interop.JET_SESID]::Nil,
        [Microsoft.Isam.Esent.Interop.JET_param]::CheckpointDepthMax,
        524288,
        $null
    )

    'PreferredVerPages', 'MaxVerPages' | ForEach-Object -Process {
        [void] [Microsoft.Isam.Esent.Interop.Api]::JetSetSystemParameter(
            $jetInstance,
            [Microsoft.Isam.Esent.Interop.JET_SESID]::Nil,
            [Microsoft.Isam.Esent.Interop.JET_param]$_,
            1024,
            $null
        )
    }

    'SystemPath', 'TempPath', 'LogFilePath' | ForEach-Object -Process {
        [void] [Microsoft.Isam.Esent.Interop.Api]::JetSetSystemParameter(
            $jetInstance,
            [Microsoft.Isam.Esent.Interop.JET_SESID]::Nil,
            [Microsoft.Isam.Esent.Interop.JET_param]$_,
            $null,
            $systemPath
        )
    }

    [void] [Microsoft.Isam.Esent.Interop.Api]::JetCreateInstance2(
        [ref]$jetInstance,
        $instanceName,
        $instanceName,
        [Microsoft.Isam.Esent.Interop.CreateInstanceGrbit]::None
    )
    

    [void] [Microsoft.Isam.Esent.Interop.Api]::JetInit2(
        [ref]$jetInstance,
        [Microsoft.Isam.Esent.Interop.InitGrbit]::None
    )

    [void] [Microsoft.Isam.Esent.Interop.Api]::JetBeginSession(
        $jetInstance,
        [ref]$sessionId,
        $null,
        $null
    )
    try {
        [void] [Microsoft.Isam.Esent.Interop.Api]::JetAttachDatabase(
            $sessionId,
            $Connection.ESEFilePath,
            [Microsoft.Isam.Esent.Interop.AttachDatabaseGrbit]$Mode
        )
        [void] [Microsoft.Isam.Esent.Interop.Api]::JetOpenDatabase(
            $sessionId,
            $Connection.ESEFilePath,
            $null,
            [ref]$dbId,
            [Microsoft.Isam.Esent.Interop.OpenDatabaseGrbit]$Mode
        )
        $Connection.Instance = $jetInstance
        $Connection.SessionId = $sessionId
        $Connection.DbId = $dbId
    } catch {
        [void] [Microsoft.Isam.Esent.Interop.Api]::JetEndSession(
            $sessionId,
            [Microsoft.Isam.Esent.Interop.EndSessionGrbit]::None
        )
        [void] [Microsoft.Isam.Esent.Interop.Api]::JetTerm($jetInstance)
        throw $_
    }
}

function Dismount-DSCPullServerESEDatabase {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [DSCPullServerESEConnection] $Connection
    )

    [void] [Microsoft.Isam.Esent.Interop.Api]::JetCloseDatabase(
        $Connection.SessionId,
        $Connection.DbId,
        [Microsoft.Isam.Esent.Interop.CloseDatabaseGrbit]::None
    )

    [void] [Microsoft.Isam.Esent.Interop.Api]::JetDetachDatabase(
        $Connection.SessionId,
        $Connection.ESEFilePath
    )

    [void] [Microsoft.Isam.Esent.Interop.Api]::JetEndSession(
        $Connection.SessionId,
        [Microsoft.Isam.Esent.Interop.EndSessionGrbit]::None
    )

    [void] [Microsoft.Isam.Esent.Interop.Api]::JetTerm(
        $Connection.Instance
    )

    $Connection.Instance = $null
    $Connection.SessionId = $null
    $Connection.DbId = $null
}

function Get-DSCPullServerESERegistration {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [DSCPullServerESEConnection] $Connection,

        [Parameter()]
        [guid] $AgentId,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [Alias('Name')]
        [string] $NodeName
    )
    $table = 'RegistrationData'
    [Microsoft.Isam.Esent.Interop.JET_TABLEID] $tableId = [Microsoft.Isam.Esent.Interop.JET_TABLEID]::Nil
    try {
        Mount-DSCPullServerESEDatabase -Connection $Connection -Mode ReadOnly
        [void] [Microsoft.Isam.Esent.Interop.Api]::JetOpenTable(
            $Connection.SessionId,
            $Connection.DbId,
            $Table,
            $null,
            0,
            [Microsoft.Isam.Esent.Interop.OpenTableGrbit]::None,
            [ref]$tableId
        )
    } catch {
        Write-Error -ErrorRecord $_ -ErrorAction Stop
    }

    try {
        [Microsoft.Isam.Esent.Interop.Api]::MoveBeforeFirst($Connection.SessionId, $tableId)
        while ([Microsoft.Isam.Esent.Interop.Api]::TryMoveNext($Connection.SessionId, $tableId)) {
            $nodeRegistration = [DSCNodeRegistration]::new()
            foreach ($column in ([Microsoft.Isam.Esent.Interop.Api]::GetTableColumns($Connection.SessionId, $tableId))) {
                if ($column.Name -eq 'IPAddress') {
                    $nodeRegistration.IPAddress = ([Microsoft.Isam.Esent.Interop.Api]::RetrieveColumnAsString(
                        $Connection.SessionId,
                        $tableId,
                        $column.Columnid
                    ) -split ';' -split ',')
                } elseif ($column.Name -eq 'ConfigurationNames') {
                    $nodeRegistration.ConfigurationNames = [Microsoft.Isam.Esent.Interop.Api]::DeserializeObjectFromColumn(
                        $Connection.SessionId,
                        $tableId,
                        $column.Columnid
                    )
                } else {
                    $nodeRegistration."$($column.Name)" = [Microsoft.Isam.Esent.Interop.Api]::RetrieveColumnAsString(
                        $Connection.SessionId,
                        $tableId,
                        $column.Columnid
                    )
                }
            }

            if ($PSBoundParameters.ContainsKey('NodeName') -and $nodeRegistration.NodeName -notlike $NodeName) {
                continue
            }

            if ($PSBoundParameters.ContainsKey('AgentId') -and $nodeRegistration.AgentId -ne $AgentId) {
                continue
            }

            $nodeRegistration
        }
    }
    finally {
        Dismount-DSCPullServerESEDatabase -Connection $Connection
    }
}

function Get-DSCPullServerESEStatusReport {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [DSCPullServerESEConnection] $Connection,

        [Parameter()]
        [Alias('Id')]
        [guid] $AgentId,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [Alias('Name')]
        [string] $NodeName,

        [Parameter()]
        [datetime] $FromStartTime,

        [Parameter()]
        [datetime] $ToStartTime
    )
    $table = 'StatusReport'
    [Microsoft.Isam.Esent.Interop.JET_TABLEID] $tableId = [Microsoft.Isam.Esent.Interop.JET_TABLEID]::Nil
    try {
        Mount-DSCPullServerESEDatabase -Connection $Connection -Mode ReadOnly
        [void] [Microsoft.Isam.Esent.Interop.Api]::JetOpenTable(
            $Connection.SessionId,
            $Connection.DbId,
            $Table,
            $null,
            0,
            [Microsoft.Isam.Esent.Interop.OpenTableGrbit]::None,
            [ref]$tableId
        )
    } catch {
        Write-Error -ErrorRecord $_ -ErrorAction Stop
    }

    try {
        [Microsoft.Isam.Esent.Interop.Api]::MoveBeforeFirst($Connection.SessionId, $tableId)

        $stringColumns = @(
            'NodeName',
            'OperationType',
            'RefreshMode',
            'Status',
            'LCMVersion',
            'ReportFormatVersion',
            'ConfigurationVersion',
            'RebootRequested'
        )

        $guidColumns = @(
            'JobId',
            'Id'
        )

        $datetimeColumns = @(
            'StartTime',
            'EndTime',
            'LastModifiedTime'
        )

        $deserializeColumns = @(
            'Errors',
            'StatusData'
        )

        while ([Microsoft.Isam.Esent.Interop.Api]::TryMoveNext($Connection.SessionId, $tableId)) {
            $statusReport = [DSCNodeStatusReport]::new()
            foreach ($column in ([Microsoft.Isam.Esent.Interop.Api]::GetTableColumns($Connection.SessionId, $tableId))) {
                if ($column.Name -in $datetimeColumns) {
                    $statusReport."$($column.Name)" = [Microsoft.Isam.Esent.Interop.Api]::RetrieveColumnAsDateTime(
                        $Connection.SessionId,
                        $tableId,
                        $column.Columnid
                    )
                } elseif ($column.Name -eq 'IPAddress') { 
                    $ipAddress = ([Microsoft.Isam.Esent.Interop.Api]::RetrieveColumnAsString(
                        $Connection.SessionId,
                        $tableId,
                        $column.Columnid,
                        [System.Text.Encoding]::Unicode
                    ) -split ';' -split ',')
                    $statusReport.IPAddress = $ipAddress.ForEach{
                        # potential for invalid ip address like empty string
                        try {
                            [void][ipaddress]::Parse($_)
                            $_
                        } catch {}
                    }
                } elseif ($column.Name -in $stringColumns) {
                    $statusReport."$($column.Name)" = ([Microsoft.Isam.Esent.Interop.Api]::RetrieveColumnAsString(
                        $Connection.SessionId,
                        $tableId,
                        $column.Columnid,
                        [System.Text.Encoding]::Unicode
                    ) -split ';' -split ',')
                } elseif ($column.Name -in $guidColumns) {
                    $statusReport."$($column.Name)" = [Microsoft.Isam.Esent.Interop.Api]::RetrieveColumnAsGuid(
                        $Connection.SessionId,
                        $tableId,
                        $column.Columnid
                    )
                } elseif ($column.Name -in $deserializeColumns) {
                    $statusReport."$($column.Name)" = [Microsoft.Isam.Esent.Interop.Api]::DeserializeObjectFromColumn(
                        $Connection.SessionId,
                        $tableId,
                        $column.Columnid
                    )
                } elseif ($column.Name -eq 'AdditionalData') {
                    $statusReport."$($column.Name)" = [Microsoft.Isam.Esent.Interop.Api]::RetrieveColumnAsString(
                        $Connection.SessionId,
                        $tableId,
                        $column.Columnid,
                        [System.Text.Encoding]::Unicode
                    ) | ConvertFrom-Json
                } else {
                    $statusReport."$($column.Name)" = [Microsoft.Isam.Esent.Interop.Api]::RetrieveColumnAsString(
                        $Connection.SessionId,
                        $tableId,
                        $column.Columnid,
                        [System.Text.Encoding]::Unicode
                    )
                }

                if ($PSBoundParameters.ContainsKey('AgentId') -and $statusReport.Id -ne $AgentId) {
                    continue
                }

                if ($PSBoundParameters.ContainsKey('NodeName') -and $statusReport.NodeName -notlike $NodeName) {
                    continue
                }

                if ($PSBoundParameters.ContainsKey('FromStartTime') -and $statusReport.FromStartTime -ge $FromStartTime) {
                    continue
                }

                if ($PSBoundParameters.ContainsKey('ToStartTime') -and $statusReport.AgentId -le $ToStartTime) {
                    continue
                }

                $statusReport
            }
        }
    }
    finally {
        Dismount-DSCPullServerESEDatabase -Connection $Connection
    }
}

function Get-DSCPullServerESEDevice {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [DSCPullServerESEConnection] $Connection,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [Alias('Name')]
        [string] $TargetName,

        [Parameter()]
        [guid] $ConfigurationID
    )
    $table = 'Devices'
    [Microsoft.Isam.Esent.Interop.JET_TABLEID] $tableId = [Microsoft.Isam.Esent.Interop.JET_TABLEID]::Nil
    try {
        Mount-DSCPullServerESEDatabase -Connection $Connection -Mode ReadOnly
        [void] [Microsoft.Isam.Esent.Interop.Api]::JetOpenTable(
            $Connection.SessionId,
            $Connection.DbId,
            $Table,
            $null,
            0,
            [Microsoft.Isam.Esent.Interop.OpenTableGrbit]::None,
            [ref]$tableId
        )
    } catch {
        Write-Error -ErrorRecord $_ -ErrorAction Stop
    }

    try {
        [Microsoft.Isam.Esent.Interop.Api]::MoveBeforeFirst($Connection.SessionId, $tableId)

        $stringColumns = @(
            'TargetName',
            'ConfigurationID',
            'ServerCheckSum',
            'TargetChecksum'
        )

        $boolColumns = @(
            'NodeCompliant',
            'Dirty'
        )

        $datetimeColumns = @(
            'LastComplianceTime',
            'LastHeartbeatTime'
        )

        while ([Microsoft.Isam.Esent.Interop.Api]::TryMoveNext($Connection.SessionId, $tableId)) {
            foreach ($column in ([Microsoft.Isam.Esent.Interop.Api]::GetTableColumns($Connection.SessionId, $tableId))) {
                $device = [DSCDevice]::new()
                if ($column.Name -in $stringColumns) {
                    $device."$($column.Name)" = [Microsoft.Isam.Esent.Interop.Api]::RetrieveColumnAsString(
                        $Connection.SessionId,
                        $tableId,
                        $column.Columnid,
                        [System.Text.Encoding]::Unicode
                    )
                } elseif ($column.Name -in $boolColumns) {
                    $row = [Microsoft.Isam.Esent.Interop.Api]::RetrieveColumnAsBoolean(
                        $Connection.SessionId,
                        $tableId,
                        $column.Columnid
                    )
                    if ($row.HasValue) {
                        $device."$($column.Name)" = $row.Value
                    }
                } elseif ($column.Name -in $datetimeColumns) {
                    $row = [Microsoft.Isam.Esent.Interop.Api]::RetrieveColumnAsDateTime(
                        $Connection.SessionId,
                        $tableId,
                        $column.Columnid
                    )
                    if ($row.HasValue) {
                        $device."$($column.Name)" = $row.Value
                    }
                } elseif ($column.Name -eq 'StatusCode') {
                    $row = [Microsoft.Isam.Esent.Interop.Api]::RetrieveColumnAsInt32(
                        $Connection.SessionId,
                        $tableId,
                        $column.Columnid
                    )
                    if ($row.HasValue) {
                        $device.StatusCode = $row.Value
                    }
                } else {
                    $device."$($column.Name)" = [Microsoft.Isam.Esent.Interop.Api]::RetrieveColumnAsString(
                        $Connection.SessionId,
                        $tableId,
                        $column.Columnid,
                        [System.Text.Encoding]::Unicode
                    )
                }
            }

            if ($PSBoundParameters.ContainsKey('TargetName') -and $device.TargetName -notlike $TargetName) {
                continue
            }
            if ($PSBoundParameters.ContainsKey('ConfigurationID') -and $device.ConfigurationID -notlike $ConfigurationID) {
                continue
            }

            $device
        }
    }
    finally {
        Dismount-DSCPullServerESEDatabase -Connection $Connection
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
            $newESEArgs = @{
                ESEFilePath = $ESEFilePath
                DontStore = $true
            }
            New-DSCPullServerAdminConnection @newESEArgs
        }
    }
}
#endregion

Export-ModuleMember -Function *-DSCPullServerAdmin*
