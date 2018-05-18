Add-Type -Path "C:\Windows\Microsoft.NET\assembly\GAC_MSIL\microsoft.isam.esent.interop\*\Microsoft.Isam.Esent.Interop.dll"

$DSCPullServerConnections = [System.Collections.ArrayList]::new()

# TODO:
# Unlock NEW, SET, REMOVE for ESE database (Now only for SQL)
# Add daterange on remove statusreport with own parameterset
# Add pipeline support for ESE (have some sort of session manager that closes the db connection only when entire pipeline is complete)
# Currently I'm unable to populate Devices table though SQL enabled Pull Server using WMF5.1 or WMF4 LCM. (PullServer bug)
# Have new connections also validate that they can actually do something with the connection or else fail
# Abstract connections into higher level management class?
# Unlock New Database function
# Unlock Migrate function
# Remove C# code
# Restructure project into multiple files and have build process to publish as single psm1

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

#region classes and enums
class DSCDevice {
    [string] $TargetName

    [guid] $ConfigurationID

    [string] $ServerCheckSum

    [string] $TargetCheckSum

    [bool] $NodeCompliant

    [nullable[datetime]] $LastComplianceTime

    [nullable[datetime]] $LastHeartbeatTime

    [bool] $Dirty

    [int32] $StatusCode

    [string] $Status = $deviceStatusCodeMap[$this.StatusCode]

    DSCDevice () {}

    DSCDevice ([System.Data.Common.DbDataRecord] $Input) {
        for ($i = 0; $i -lt $Input.FieldCount; $i++) {
            $name = $Input.GetName($i)
            if (([DBNull]::Value).Equals($Input[$i])) {
                $this."$name" = $null
            } else {
                $this."$name" = $Input[$i]
            }
        }
    }

    [string] GetSQLUpdate () {
        $query = "UPDATE Devices Set {0} WHERE TargetName = '{1}'" -f @(
            (($this | Get-Member -MemberType Property).Where{
                $_.Name -notin 'TargetName', 'Status'
            }.foreach{
                if ($_.Definition.Split(' ')[0] -eq 'datetime') {
                    if ($this."$($_.Name)".ToString('yyyy-MM-dd HH:mm:ss') -eq '0001-01-01 00:00:00') {
                        "$($_.Name) = NULL"
                    } else {
                        "$($_.Name) = '{0}'" -f $this."$($_.Name)".ToString('yyyy-MM-dd HH:mm:ss')
                    }
                } else {
                    "$($_.Name) = '{0}'" -f $this."$($_.Name)"
                }
            } -join ','),
            $this.TargetName
        )
        return $query
    }

    [string] GetSQLInsert () {
        $query = ("INSERT INTO Devices ({0}) VALUES ({1})" -f @(
            (($this | Get-Member -MemberType Property | Where-Object -FilterScript {$_.Name -ne 'Status'}).Name -join ','),
            (($this | Get-Member -MemberType Property).ForEach{
                if ($_.Name -eq 'Status') {
                    return
                } else {
                    if ($_.Definition.Split(' ')[0] -eq 'datetime') {
                        if ($this."$($_.Name)".ToString('yyyy-MM-dd HH:mm:ss') -eq '0001-01-01 00:00:00') {
                            'NULL'
                        } else {
                            "'{0}'" -f $this."$($_.Name)".ToString('yyyy-MM-dd HH:mm:ss')
                        }
                    } else {
                        "'{0}'" -f $this."$($_.Name)"
                    }
                }
            } -join ',')
        ))
        return $query
    }

    [string] GetSQLDelete () {
        return ("DELETE FROM Devices WHERE TargetName = '{0}'" -f $this.TargetName)
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
                    if ($this.ConfigurationNames.Count -ge 1) {
                        "$($_.Name) = '[`"{0}`"]'" -f ($this."$($_.Name)" -join '","')
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

    [datetime] $LastModifiedTime # Only applicable for ESENT, Not present in SQL

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

    [string] GetSQLUpdate () {
        $query = "UPDATE StatusReport Set {0} WHERE JobId = '{1}'" -f @(
            (($this | Get-Member -MemberType Property).Where{
                $_.Name -ne 'JobId'
            }.foreach{
                if ($_.Name -eq 'LastModifiedTime') {
                    # skip as missing in SQL table, only present in EDB
                } elseif ($_.Name -eq 'IPAddress') {
                    "$($_.Name) = '{0}'" -f ($this."$($_.Name)" -join ';')
                } elseif ($_.Name -in 'StatusData', 'Errors') {
                    "$($_.Name) = '[{0}]'" -f (($this."$($_.Name)" | ConvertTo-Json -Compress -Depth 100) | ConvertTo-Json -Compress)
                } elseif ($_.Name -eq 'AdditionalData') {
                    "$($_.Name) = '[{0}]'" -f ($this."$($_.Name)" | ConvertTo-Json -Compress -Depth 100)
                } else {
                    if ($_.Definition.Split(' ')[0] -eq 'datetime') {
                        if ($this."$($_.Name)".ToString('yyyy-MM-dd HH:mm:ss') -eq '0001-01-01 00:00:00') {
                            "$($_.Name) = NULL"
                        } else {
                            "$($_.Name) = '{0}'" -f $this."$($_.Name)".ToString('yyyy-MM-dd HH:mm:ss')
                        }
                    } else {
                        "$($_.Name) = '{0}'" -f $this."$($_.Name)"
                    }
                }
            } -join ','),
            $this.JobId
        )
        return $query
    }

    [string] GetSQLInsert () {
        $query = ("INSERT INTO StatusReport ({0}) VALUES ({1})" -f @(
            (($this | Get-Member -MemberType Property | Where-Object -FilterScript {$_.Name -ne 'LastModifiedTime'}).Name -join ','),
            (($this | Get-Member -MemberType Property).ForEach{
                if ($_.Name -eq 'LastModifiedTime') {
                    # skip as missing in SQL table, only present in EDB
                } elseif ($_.Name -eq 'IPAddress') {
                    "'{0}'" -f ($this."$($_.Name)" -join ';')
                } elseif ($_.Name -in 'StatusData', 'Errors') {
                    "'[{0}]'" -f (($this."$($_.Name)" | ConvertTo-Json -Compress -Depth 100) | ConvertTo-Json -Compress)
                } elseif ($_.Name -eq 'AdditionalData') {
                    "'{0}'" -f ($this."$($_.Name)" | ConvertTo-Json -Compress -Depth 100)
                } else {
                    if ($_.Definition.Split(' ')[0] -eq 'datetime') {
                        if ($this."$($_.Name)".ToString('yyyy-MM-dd HH:mm:ss') -eq '0001-01-01 00:00:00') {
                            'NULL'
                        } else {
                            "'{0}'" -f $this."$($_.Name)".ToString('yyyy-MM-dd HH:mm:ss')
                        }
                    } else {
                        "'{0}'" -f $this."$($_.Name)"
                    }
                }
            } -join ',')
        ))
        return $query
    }

    [string] GetSQLDelete () {
        return ("DELETE FROM StatusReport WHERE JobId = '{0}'" -f $this.JobId)
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
        [guid] $JobId,

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
                    $eseParams.Add('FromStartTime', $FromStartTime)
                }
                if ($PSBoundParameters.ContainsKey('ToStartTime')) {
                    $eseParams.Add('ToStartTime', $ToStartTime)
                }
                if ($PSBoundParameters.ContainsKey('JobId')) {
                    $eseParams.Add('JobId', $JobId)
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
                if ($PSBoundParameters.ContainsKey("JobId")) {
                    [void] $filters.Add(("JobId = '{0}'" -f $JobId))
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
        [Parameter(Mandatory)]
        [guid] $AgentId,

        [Parameter()]
        [ValidateSet('2.0')]
        [string] $LCMVersion = '2.0',

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string] $NodeName,

        [Parameter()]
        [IPAddress[]] $IPAddress,

        [Parameter()]
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
        if ($null -ne $existingRegistration) {
            throw "A NodeRegistration with AgentId '$AgentId' already exists."
        } else {
            $tsqlScript = $nodeRegistration.GetSQLInsert()
        }

        if ($PSCmdlet.ShouldProcess("$($Connection.SQLServer)\$($Connection.Database)", $tsqlScript)) {
            Invoke-DSCPullServerSQLCommand -Connection $Connection -CommandType Set -Script $tsqlScript
        }
    }
}

function New-DSCPullServerAdminDevice {
    [CmdletBinding(
        DefaultParameterSetName = 'Connection',
        ConfirmImpact = 'Medium',
        SupportsShouldProcess
    )]
    param (
        [Parameter(Mandatory)]
        [guid] $ConfigurationID,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string] $TargetName,

        [Parameter()]
        [string] $ServerCheckSum,

        [Parameter()]
        [string] $TargetCheckSum,

        [Parameter()]
        [bool] $NodeCompliant,

        [Parameter()]
        [datetime] $LastComplianceTime,

        [Parameter()]
        [datetime] $LastHeartbeatTime,

        [Parameter()]
        [bool] $Dirty,

        [Parameter()]
        [uint32] $StatusCode,

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
        $device = [DSCDevice]::new()
        $PSBoundParameters.Keys.Where{
            $_ -in ($device | Get-Member -MemberType Property | Where-Object -FilterScript {$_.Name -ne 'Status'} ).Name
        }.ForEach{
            $device.$_ = $PSBoundParameters.$_
        }

        $existingDevice = Get-DSCPullServerAdminDevice -Connection $Connection -TargetName $device.TargetName
        if ($null -ne $existingDevice) {
            throw "A Device with TargetName '$TargetName' already exists."
        } else {
            $tsqlScript = $device.GetSQLInsert()
        }

        if ($PSCmdlet.ShouldProcess("$($Connection.SQLServer)\$($Connection.Database)", $tsqlScript)) {
            Invoke-DSCPullServerSQLCommand -Connection $Connection -CommandType Set -Script $tsqlScript
        }
    }
}

function New-DSCPullServerAdminStatusReport {
    [CmdletBinding(
        DefaultParameterSetName = 'Connection',
        ConfirmImpact = 'Medium',
        SupportsShouldProcess
    )]
    param (
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [guid] $JobId,

        [Parameter()]
        [Guid] $Id = [guid]::NewGuid(),

        [Parameter()]
        [string] $OperationType,

        [Parameter()]
        [string] $RefreshMode,

        [Parameter()]
        [string] $Status,

        [Parameter()]
        [string] $LCMVersion,

        [Parameter()]
        [string] $ReportFormatVersion,

        [Parameter()]
        [string] $ConfigurationVersion,

        [Parameter()]
        [string] $NodeName,

        [Parameter()]
        [IPAddress[]] $IPAddress,

        [Parameter()]
        [datetime] $StartTime,

        [Parameter()]
        [datetime] $EndTime,

        [Parameter()]
        [datetime] $LastModifiedTime,

        [Parameter()]
        [PSObject[]] $Errors,

        [Parameter()]
        [PSObject[]] $StatusData,

        [Parameter()]
        [bool] $RebootRequested,

        [Parameter()]
        [PSObject[]] $AdditionalData,

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
        $report = [DSCNodeStatusReport]::new()
        $PSBoundParameters.Keys.Where{
            $_ -in ($report | Get-Member -MemberType Property).Name
        }.ForEach{
            $report.$_ = $PSBoundParameters.$_
        }

        $existingReport = Get-DSCPullServerAdminStatusReport -Connection $Connection -JobId $report.JobId
        if ($null -ne $existingReport) {
            throw "A Report with JobId '$JobId' already exists."
        } else {
            $tsqlScript = $report.GetSQLInsert()
        }

        if ($PSCmdlet.ShouldProcess("$($Connection.SQLServer)\$($Connection.Database)", $tsqlScript)) {
            Invoke-DSCPullServerSQLCommand -Connection $Connection -CommandType Set -Script $tsqlScript
        }
    }
}
#endregion

#region table Set functions
function Set-DSCPullServerAdminRegistration {
    [CmdletBinding(
        DefaultParameterSetName = 'InputObject_Connection',
        ConfirmImpact = 'Medium',
        SupportsShouldProcess
    )]
    param (
        [Parameter(Mandatory, ValueFromPipeline, ParameterSetName = 'InputObject_Connection')]
        [Parameter(Mandatory, ValueFromPipeline, ParameterSetName = 'InputObject_SQL')]
        [DSCNodeRegistration] $InputObject,

        [Parameter(Mandatory, ParameterSetName = 'Manual_Connection')]
        [Parameter(Mandatory, ParameterSetName = 'Manual_SQL')]
        [guid] $AgentId,

        [Parameter()]
        [ValidateSet('2.0')]
        [string] $LCMVersion = '2.0',

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string] $NodeName,

        [Parameter()]
        [IPAddress[]] $IPAddress,

        [Parameter()]
        [string[]] $ConfigurationNames,

        [Parameter(ParameterSetName = 'InputObject_Connection')]
        [Parameter(ParameterSetName = 'Manual_Connection')]
        [DSCPullServerSQLConnection] $Connection = (Get-DSCPullServerAdminConnection -OnlyShowActive -Type SQL),

        [Parameter(Mandatory, ParameterSetName = 'InputObject_SQL')]
        [Parameter(Mandatory, ParameterSetName = 'Manual_SQL')]
        [ValidateNotNullOrEmpty()]
        [Alias('SQLInstance')]
        [string] $SQLServer,

        [Parameter(ParameterSetName = 'InputObject_SQL')]
        [Parameter(ParameterSetName = 'Manual_SQL')]
        [pscredential] $Credential,

        [Parameter(ParameterSetName = 'InputObject_SQL')]
        [Parameter(ParameterSetName = 'Manual_SQL')]
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
        if (-not $PSBoundParameters.ContainsKey('InputObject')) {
            $existingRegistration = Get-DSCPullServerAdminRegistration -Connection $Connection -AgentId $nodeRegistration.AgentId
            if ($null -eq $existingRegistration) {
                throw "A NodeRegistration with AgentId '$AgentId' was not found"
            }
        } else {
            $existingRegistration = $InputObject
        }

        $PSBoundParameters.Keys.Where{
            $_ -in ($existingRegistration | Get-Member -MemberType Property).Name
        }.ForEach{
            if ($null -ne $PSBoundParameters.$_) {
                $existingRegistration.$_ = $PSBoundParameters.$_
            }
        }

        $tsqlScript = $existingRegistration.GetSQLUpdate()

        if ($PSCmdlet.ShouldProcess("$($Connection.SQLServer)\$($Connection.Database)", $tsqlScript)) {
            Invoke-DSCPullServerSQLCommand -Connection $Connection -CommandType Set -Script $tsqlScript
        }
    }
}

function Set-DSCPullServerAdminDevice {
    [CmdletBinding(
        DefaultParameterSetName = 'InputObject_Connection',
        ConfirmImpact = 'Medium',
        SupportsShouldProcess
    )]
    param (
        [Parameter(Mandatory, ValueFromPipeline, ParameterSetName = 'InputObject_Connection')]
        [Parameter(Mandatory, ValueFromPipeline, ParameterSetName = 'InputObject_SQL')]
        [DSCDevice] $InputObject,

        [Parameter(Mandatory, ParameterSetName = 'Manual_Connection')]
        [Parameter(Mandatory, ParameterSetName = 'Manual_SQL')]
        [guid] $ConfigurationID,

        [Parameter(Mandatory, ParameterSetName = 'Manual_Connection')]
        [Parameter(Mandatory, ParameterSetName = 'Manual_SQL')]
        [ValidateNotNullOrEmpty()]
        [string] $TargetName,

        [Parameter()]
        [string] $ServerCheckSum,

        [Parameter()]
        [string] $TargetCheckSum,

        [Parameter()]
        [bool] $NodeCompliant,

        [Parameter()]
        [datetime] $LastComplianceTime,

        [Parameter()]
        [datetime] $LastHeartbeatTime,

        [Parameter()]
        [bool] $Dirty,

        [Parameter()]
        [uint32] $StatusCode,

        [Parameter(ParameterSetName = 'InputObject_Connection')]
        [Parameter(ParameterSetName = 'Manual_Connection')]
        [DSCPullServerSQLConnection] $Connection = (Get-DSCPullServerAdminConnection -OnlyShowActive -Type SQL),

        [Parameter(Mandatory, ParameterSetName = 'InputObject_SQL')]
        [Parameter(Mandatory, ParameterSetName = 'Manual_SQL')]
        [ValidateNotNullOrEmpty()]
        [Alias('SQLInstance')]
        [string] $SQLServer,

        [Parameter(ParameterSetName = 'InputObject_SQL')]
        [Parameter(ParameterSetName = 'Manual_SQL')]
        [pscredential] $Credential,

        [Parameter(ParameterSetName = 'InputObject_SQL')]
        [Parameter(ParameterSetName = 'Manual_SQL')]
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
        if (-not $PSBoundParameters.ContainsKey('InputObject')) {
            $existingDevice = Get-DSCPullServerAdminDevice -Connection $Connection -TargetName $TargetName
        } else {
            $existingDevice = $InputObject
        }

        if ($null -eq $existingDevice) {
            throw "A Device with TargetName '$TargetName' was not found"
        } else {
            $PSBoundParameters.Keys.Where{
                $_ -in ($existingDevice | Get-Member -MemberType Property | Where-Object -FilterScript {$_.Name -ne 'Status'} ).Name
            }.ForEach{
                if ($null -ne $PSBoundParameters.$_) {
                    $existingDevice.$_ = $PSBoundParameters.$_
                }
            }
            $tsqlScript = $existingDevice.GetSQLUpdate()

            if ($PSCmdlet.ShouldProcess("$($Connection.SQLServer)\$($Connection.Database)", $tsqlScript)) {
                Invoke-DSCPullServerSQLCommand -Connection $Connection -CommandType Set -Script $tsqlScript
            }
        }
    }
}

function Set-DSCPullServerAdminStatusReport {
    [CmdletBinding(
        DefaultParameterSetName = 'InputObject_Connection',
        ConfirmImpact = 'Medium',
        SupportsShouldProcess
    )]
    param (
        [Parameter(Mandatory, ValueFromPipeline, ParameterSetName = 'InputObject_Connection')]
        [Parameter(Mandatory, ValueFromPipeline, ParameterSetName = 'InputObject_SQL')]
        [DSCNodeStatusReport] $InputObject,

        [Parameter(Mandatory, ParameterSetName = 'Manual_Connection')]
        [Parameter(Mandatory, ParameterSetName = 'Manual_SQL')]
        [guid] $JobId,

        [Parameter()]
        [Guid] $Id,

        [Parameter()]
        [string] $OperationType,

        [Parameter()]
        [string] $RefreshMode,

        [Parameter()]
        [string] $Status,

        [Parameter()]
        [string] $LCMVersion,

        [Parameter()]
        [string] $ReportFormatVersion,

        [Parameter()]
        [string] $ConfigurationVersion,

        [Parameter()]
        [string] $NodeName,

        [Parameter()]
        [IPAddress[]] $IPAddress,

        [Parameter()]
        [datetime] $StartTime,

        [Parameter()]
        [datetime] $EndTime,

        [Parameter()]
        [datetime] $LastModifiedTime,

        [Parameter()]
        [PSObject[]] $Errors,

        [Parameter()]
        [PSObject[]] $StatusData,

        [Parameter()]
        [bool] $RebootRequested,

        [Parameter()]
        [PSObject[]] $AdditionalData,

        [Parameter(ParameterSetName = 'InputObject_Connection')]
        [Parameter(ParameterSetName = 'Manual_Connection')]
        [DSCPullServerSQLConnection] $Connection = (Get-DSCPullServerAdminConnection -OnlyShowActive -Type SQL),

        [Parameter(Mandatory, ParameterSetName = 'InputObject_SQL')]
        [Parameter(Mandatory, ParameterSetName = 'Manual_SQL')]
        [ValidateNotNullOrEmpty()]
        [Alias('SQLInstance')]
        [string] $SQLServer,

        [Parameter(ParameterSetName = 'InputObject_SQL')]
        [Parameter(ParameterSetName = 'Manual_SQL')]
        [pscredential] $Credential,

        [Parameter(ParameterSetName = 'InputObject_SQL')]
        [Parameter(ParameterSetName = 'Manual_SQL')]
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
        if (-not $PSBoundParameters.ContainsKey('InputObject')) {
            $existingReport = Get-DSCPullServerAdminStatusReport -Connection $Connection -JobId $JobId
        } else {
            $existingReport = $InputObject
        }

        if ($null -eq $existingReport) {
            throw "A Report with JobId '$JobId' was not found"
        } else {
            $PSBoundParameters.Keys.Where{
                $_ -in ($existingReport | Get-Member -MemberType Property).Name
            }.ForEach{
                if ($null -ne $PSBoundParameters.$_) {
                    $existingReport.$_ = $PSBoundParameters.$_
                }
            }
            $tsqlScript = $existingReport.GetSQLUpdate()

            if ($PSCmdlet.ShouldProcess("$($Connection.SQLServer)\$($Connection.Database)", $tsqlScript)) {
                Invoke-DSCPullServerSQLCommand -Connection $Connection -CommandType Set -Script $tsqlScript
            }
        }
    }
}
#endregion

#region table Remove functions
function Remove-DSCPullServerAdminRegistration {
    [CmdletBinding(
        DefaultParameterSetName = 'InputObject_Connection',
        ConfirmImpact = 'High',
        SupportsShouldProcess
    )]
    param (
        [Parameter(Mandatory, ValueFromPipeline, ParameterSetName = 'InputObject_Connection')]
        [Parameter(Mandatory, ValueFromPipeline, ParameterSetName = 'InputObject_SQL')]
        [DSCNodeRegistration] $InputObject,

        [Parameter(Mandatory, ParameterSetName = 'Manual_Connection')]
        [Parameter(Mandatory, ParameterSetName = 'Manual_SQL')]
        [guid] $AgentId,

        [Parameter(ParameterSetName = 'InputObject_Connection')]
        [Parameter(ParameterSetName = 'Manual_Connection')]
        [DSCPullServerSQLConnection] $Connection = (Get-DSCPullServerAdminConnection -OnlyShowActive -Type SQL),

        [Parameter(Mandatory, ParameterSetName = 'InputObject_SQL')]
        [Parameter(Mandatory, ParameterSetName = 'Manual_SQL')]
        [ValidateNotNullOrEmpty()]
        [Alias('SQLInstance')]
        [string] $SQLServer,

        [Parameter(ParameterSetName = 'InputObject_SQL')]
        [Parameter(ParameterSetName = 'Manual_SQL')]
        [pscredential] $Credential,

        [Parameter(ParameterSetName = 'InputObject_SQL')]
        [Parameter(ParameterSetName = 'Manual_SQL')]
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
        if (-not $PSBoundParameters.ContainsKey('InputObject')) {
            $existingRegistration = Get-DSCPullServerAdminRegistration -Connection $Connection -AgentId $AgentId
        } else {
            $existingRegistration = $InputObject
        }

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

function Remove-DSCPullServerAdminDevice {
    [CmdletBinding(
        DefaultParameterSetName = 'InputObject_Connection',
        ConfirmImpact = 'High',
        SupportsShouldProcess
    )]
    param (
        [Parameter(Mandatory, ValueFromPipeline, ParameterSetName = 'InputObject_Connection')]
        [Parameter(Mandatory, ValueFromPipeline, ParameterSetName = 'InputObject_SQL')]
        [DSCDevice] $InputObject,

        [Parameter(Mandatory, ParameterSetName = 'Manual_Connection')]
        [Parameter(Mandatory, ParameterSetName = 'Manual_SQL')]
        [string] $TargetName,

        [Parameter(ParameterSetName = 'InputObject_Connection')]
        [Parameter(ParameterSetName = 'Manual_Connection')]
        [DSCPullServerSQLConnection] $Connection = (Get-DSCPullServerAdminConnection -OnlyShowActive -Type SQL),

        [Parameter(Mandatory, ParameterSetName = 'InputObject_SQL')]
        [Parameter(Mandatory, ParameterSetName = 'Manual_SQL')]
        [ValidateNotNullOrEmpty()]
        [Alias('SQLInstance')]
        [string] $SQLServer,

        [Parameter(ParameterSetName = 'InputObject_SQL')]
        [Parameter(ParameterSetName = 'Manual_SQL')]
        [pscredential] $Credential,

        [Parameter(ParameterSetName = 'InputObject_SQL')]
        [Parameter(ParameterSetName = 'Manual_SQL')]
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
        if (-not $PSBoundParameters.ContainsKey('InputObject')) {
            $existingDevice = Get-DSCPullServerAdminDevice -Connection $Connection -TargetName $TargetName
        } else {
            $existingDevice = $InputObject
        }

        if ($null -eq $existingDevice) {
            Write-Warning -Message "A Device with TargetName '$TargetName' was not found"
        } else {
            $tsqlScript = $existingDevice.GetSQLDelete()
            if ($PSCmdlet.ShouldProcess("$($Connection.SQLServer)\$($Connection.Database)", $tsqlScript)) {
                Invoke-DSCPullServerSQLCommand -Connection $Connection -CommandType Set -Script $tsqlScript
            }
        }
    }
}

function Remove-DSCPullServerAdminStatusReport {
    [CmdletBinding(
        DefaultParameterSetName = 'InputObject_Connection',
        ConfirmImpact = 'High',
        SupportsShouldProcess
    )]
    param (
        [Parameter(Mandatory, ValueFromPipeline, ParameterSetName = 'InputObject_Connection')]
        [Parameter(Mandatory, ValueFromPipeline, ParameterSetName = 'InputObject_SQL')]
        [DSCNodeStatusReport] $InputObject,

        [Parameter(Mandatory, ParameterSetName = 'Manual_Connection')]
        [Parameter(Mandatory, ParameterSetName = 'Manual_SQL')]
        [guid] $JobId,

        [Parameter(ParameterSetName = 'InputObject_Connection')]
        [Parameter(ParameterSetName = 'Manual_Connection')]
        [DSCPullServerSQLConnection] $Connection = (Get-DSCPullServerAdminConnection -OnlyShowActive -Type SQL),

        [Parameter(Mandatory, ParameterSetName = 'InputObject_SQL')]
        [Parameter(Mandatory, ParameterSetName = 'Manual_SQL')]
        [ValidateNotNullOrEmpty()]
        [Alias('SQLInstance')]
        [string] $SQLServer,

        [Parameter(ParameterSetName = 'InputObject_SQL')]
        [Parameter(ParameterSetName = 'Manual_SQL')]
        [pscredential] $Credential,

        [Parameter(ParameterSetName = 'InputObject_SQL')]
        [Parameter(ParameterSetName = 'Manual_SQL')]
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
        if (-not $PSBoundParameters.ContainsKey('InputObject')) {
            $existingReport = Get-DSCPullServerAdminStatusReport -Connection $Connection -JobId $JobId
        } else {
            $existingReport = $InputObject
        }

        if ($null -eq $existingReport) {
            Write-Warning -Message "A Report with JobId '$JobId' was not found"
        } else {
            $tsqlScript = $existingReport.GetSQLDelete()
            if ($PSCmdlet.ShouldProcess("$($Connection.SQLServer)\$($Connection.Database)", $tsqlScript)) {
                Invoke-DSCPullServerSQLCommand -Connection $Connection -CommandType Set -Script $tsqlScript
            }
        }
    }
}
#endregion

#region database functions
function Copy-DSCPullServerAdminDataESEToSQL {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [DSCPullServerESEConnection] $ESEConnection,

        [Parameter(Mandatory)]
        [DSCPullServerSQLConnection] $SQLConnection,

        [Parameter()]
        [ValidateSet('Devices', 'RegistrationData', 'StatusReports')]
        [string[]] $ObjectsToMigrate = @('Devices', 'RegistrationData'),

        [Parameter()]
        [switch] $Force
    )

    switch ($ObjectsToMigrate) {
        Devices {
            $devices = Get-DSCPullServerAdminDevice -Connection $ESEConnection
            foreach ($d in $devices) {
                $sqlD = Get-DSCPullServerAdminDevice -Connection $SQLConnection -TargetName $d.TargetName
                if ($null -eq $sqlD) {
                    if ($PSCmdlet.ShouldProcess($d.TargetName, "Create new device on $($SQLConnection.SQLServer)\$($SQLConnection.Database)")) {
                        Invoke-DSCPullServerSQLCommand -Connection $SQLConnection -CommandType Set -Script ($d.GetSQLInsert())
                    }
                } else {
                    if ($PSCmdlet.ShouldProcess($d.TargetName, "Replace existing device on $($SQLConnection.SQLServer)\$($SQLConnection.Database)")) {
                        if ($Force) {
                            Invoke-DSCPullServerSQLCommand -Connection $SQLConnection -CommandType Set -Script ($sqlD.GetSQLDelete())
                            Invoke-DSCPullServerSQLCommand -Connection $SQLConnection -CommandType Set -Script ($d.GetSQLInsert())
                        } else {
                            Write-Warning -Message "Unable to replace device $($d.TargetName) as Force switch was not set"
                        }
                    }
                }
            }
        }
        RegistrationData {
            $registrations = Get-DSCPullServerAdminRegistration -Connection $ESEConnection
            foreach ($r in $registrations) {
                $sqlReg = Get-DSCPullServerAdminRegistration -Connection $SQLConnection -AgentId $r.AgentId
                if ($null -eq $sqlReg) {
                    if ($PSCmdlet.ShouldProcess($r.AgentId, "Create new Registration on $($SQLConnection.SQLServer)\$($SQLConnection.Database)")) {
                        Invoke-DSCPullServerSQLCommand -Connection $SQLConnection -CommandType Set -Script ($r.GetSQLInsert())
                    }
                } else {
                    if ($PSCmdlet.ShouldProcess($r.AgentId, "Replace existing Registration on $($SQLConnection.SQLServer)\$($SQLConnection.Database)")) {
                        if ($Force) {
                            Invoke-DSCPullServerSQLCommand -Connection $SQLConnection -CommandType Set -Script ($sqlReg.GetSQLDelete())
                            Invoke-DSCPullServerSQLCommand -Connection $SQLConnection -CommandType Set -Script ($r.GetSQLInsert())
                        } else {
                            Write-Warning -Message "Unable to replace Registration $($r.AgentId) as Force switch was not set"
                        }
                    }
                }
            }
        }
        StatusReports {
            $reports = Get-DSCPullServerAdminStatusReport -Connection $ESEConnection
            foreach ($r in $reports) {
                $sqlRep = Get-DSCPullServerAdminStatusReport -Connection $SQLConnection -JobId $r.JobId -AgentId $r.Id
                if ($null -eq $sqlRep) {
                    if ($PSCmdlet.ShouldProcess($r.JobId, "Create new StatusReport on $($SQLConnection.SQLServer)\$($SQLConnection.Database)")) {
                        Invoke-DSCPullServerSQLCommand -Connection $SQLConnection -CommandType Set -Script ($r.GetSQLInsert())
                    }
                } else {
                    if ($PSCmdlet.ShouldProcess($r.JobId, "Replace StatusReport Registration on $($SQLConnection.SQLServer)\$($SQLConnection.Database)")) {
                        if ($Force) {
                            Invoke-DSCPullServerSQLCommand -Connection $SQLConnection -CommandType Set -Script ($sqlRep.GetSQLDelete())
                            Invoke-DSCPullServerSQLCommand -Connection $SQLConnection -CommandType Set -Script ($r.GetSQLInsert())
                        } else {
                            Write-Warning -Message "Unable to replace StatusReport $($r.JobId) as Force switch was not set"
                        }
                    }
                }
            }
        }
    }
}

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
        [datetime] $ToStartTime,

        [Parameter()]
        [guid] $JobId
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

            if ($PSBoundParameters.ContainsKey('JobId') -and $statusReport.JobId -ne $JobId) {
                continue
            }

            $statusReport
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
                } elseif ($column.Name -eq 'ConfigurationID') {
                    $device."$($column.Name)" = [Microsoft.Isam.Esent.Interop.Api]::RetrieveColumnAsGuid(
                        $Connection.SessionId,
                        $tableId,
                        $column.Columnid
                    )
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
        [string] $ParameterSetName,

        [DSCPullServerConnection] $Connection,

        [string] $SQLServer,

        [pscredential] $Credential,

        [string] $Database,

        [string] $ESEFilePath,

        [Parameter(ValueFromRemainingArguments)]
        $DroppedParams
    )

    switch -Wildcard ($ParameterSetName) {
        *Connection {
            if (Test-DefaultDSCPullServerConnection $Connection) {
                return $Connection
            }
        }
        *SQL {
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
        *ESE {
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
