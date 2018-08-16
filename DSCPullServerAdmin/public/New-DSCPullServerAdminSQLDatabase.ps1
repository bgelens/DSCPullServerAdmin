<#
    .SYNOPSIS
    Creates a DSC Pull Server SQL Database.

    .DESCRIPTION
    Normally, the DSC Pull Server database is created when the first
    interaction with the Pull Server takes place. This function allows
    for prestaging the database.

    .PARAMETER SQLServer
    Define the SQL Instance where the database should be created.

    .PARAMETER Credential
    Define the Credentials to be used with the SQL Server connection.

    .PARAMETER Name
    Define the Database name to create.

    .EXAMPLE
    New-DSCPullServerAdminSQLDatabase -SQLServer sqlserver\instance -Name dscdb
#>
function New-DSCPullServerAdminSQLDatabase {
    [CmdletBinding(
        ConfirmImpact = 'High',
        SupportsShouldProcess
    )]
    param(
        [Parameter(Mandatory, ParameterSetName = 'SQL')]
        [ValidateNotNullOrEmpty()]
        [Alias('SQLInstance')]
        [string] $SQLServer,

        [Parameter(ParameterSetName = 'SQL')]
        [pscredential] $Credential,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [Alias('Database')]
        [string] $Name
    )

    $connection = [DSCPullServerSQLConnection]::new($SQLServer)
    if ($PSBoundParameters.ContainsKey('Credential')) {
        $connection.Credential = $Credential
    }

    $dbExists = Test-DSCPullServerDatabaseExist @PSBoundParameters -ErrorAction Stop
    if ($dbExists) {
        Write-Warning -Message "Database $Name on $SQLServer already exists"
    } else {
        $createDbScript = "CREATE DATABASE {0}"-f $Name
        if ($PSCmdlet.ShouldProcess("$($Connection.SQLServer)\$Name", $createDbScript)) {
            Invoke-DSCPullServerSQLCommand -Connection $connection -CommandType Set -Script $createDbScript -CommandTimeOut 600
        }
        $connection.Database = $Name
        @(
            "CREATE TABLE [dbo].[Devices] ([TargetName] VARCHAR (255) NOT NULL,[ConfigurationID] VARCHAR (255) NOT NULL,[ServerCheckSum] VARCHAR (255) NOT NULL,[TargetCheckSum] VARCHAR (255) NOT NULL,[NodeCompliant] BIT DEFAULT ((0)) NOT NULL,[LastComplianceTime] DATETIME NULL,[LastHeartbeatTime] DATETIME NULL,[Dirty] BIT DEFAULT ((1)) NULL,[StatusCode] INT DEFAULT ((-1)) NULL);",
            "CREATE TABLE [dbo].[RegistrationData] ([AgentId] VARCHAR (MAX) NOT NULL,[LCMVersion] VARCHAR (255) NULL,[NodeName] VARCHAR (255) NULL,[IPAddress] VARCHAR (255) NULL,[ConfigurationNames] VARCHAR (MAX) NULL);",
            "CREATE TABLE [dbo].[StatusReport] ([JobId] VARCHAR (255) NOT NULL,[Id] VARCHAR (255) NOT NULL,[OperationType] VARCHAR (255) NULL,[RefreshMode] VARCHAR (255) NULL,[Status] VARCHAR (255) NULL,[LCMVersion] VARCHAR (255) NULL,[ReportFormatVersion] VARCHAR (255) NULL,[ConfigurationVersion] VARCHAR (255) NULL,[NodeName] VARCHAR (255) NULL,[IPAddress] VARCHAR (255) NULL,[StartTime] DATETIME DEFAULT (getdate()) NULL,[EndTime] DATETIME DEFAULT (getdate()) NULL,[Errors] VARCHAR (MAX) NULL,[StatusData] VARCHAR (MAX) NULL,[RebootRequested] VARCHAR (255) NULL,[AdditionalData]VARCHAR (MAX) NULL);"
        ) | ForEach-Object -Process {
            if ($PSCmdlet.ShouldProcess("$($Connection.SQLServer)\$Name", $_)) {
                Invoke-DSCPullServerSQLCommand -Connection $connection -CommandType Set -Script $_ -CommandTimeOut 300
            }
        }
    }
}
