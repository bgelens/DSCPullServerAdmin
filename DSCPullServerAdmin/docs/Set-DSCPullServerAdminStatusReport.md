---
external help file: DSCPullServerAdmin-help.xml
Module Name: DSCPullServerAdmin
online version:
schema: 2.0.0
---

# Set-DSCPullServerAdminStatusReport

## SYNOPSIS
Overwrites status report entries (LCMv2) in a Pull Server Database.

## SYNTAX

### InputObject_Connection (Default)
```
Set-DSCPullServerAdminStatusReport -InputObject <DSCNodeStatusReport> [-Id <Guid>] [-OperationType <String>]
 [-RefreshMode <String>] [-Status <String>] [-LCMVersion <String>] [-ReportFormatVersion <String>]
 [-ConfigurationVersion <String>] [-NodeName <String>] [-IPAddress <IPAddress[]>] [-StartTime <DateTime>]
 [-EndTime <DateTime>] [-LastModifiedTime <DateTime>] [-Errors <PSObject[]>] [-StatusData <PSObject[]>]
 [-RebootRequested <Boolean>] [-AdditionalData <PSObject[]>] [-Connection <DSCPullServerSQLConnection>]
 [-WhatIf] [-Confirm] [<CommonParameters>]
```

### InputObject_SQL
```
Set-DSCPullServerAdminStatusReport -InputObject <DSCNodeStatusReport> [-Id <Guid>] [-OperationType <String>]
 [-RefreshMode <String>] [-Status <String>] [-LCMVersion <String>] [-ReportFormatVersion <String>]
 [-ConfigurationVersion <String>] [-NodeName <String>] [-IPAddress <IPAddress[]>] [-StartTime <DateTime>]
 [-EndTime <DateTime>] [-LastModifiedTime <DateTime>] [-Errors <PSObject[]>] [-StatusData <PSObject[]>]
 [-RebootRequested <Boolean>] [-AdditionalData <PSObject[]>] -SQLServer <String> [-Credential <PSCredential>]
 [-Database <String>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

### Manual_SQL
```
Set-DSCPullServerAdminStatusReport -JobId <Guid> [-Id <Guid>] [-OperationType <String>] [-RefreshMode <String>]
 [-Status <String>] [-LCMVersion <String>] [-ReportFormatVersion <String>] [-ConfigurationVersion <String>]
 [-NodeName <String>] [-IPAddress <IPAddress[]>] [-StartTime <DateTime>] [-EndTime <DateTime>]
 [-LastModifiedTime <DateTime>] [-Errors <PSObject[]>] [-StatusData <PSObject[]>] [-RebootRequested <Boolean>]
 [-AdditionalData <PSObject[]>] -SQLServer <String> [-Credential <PSCredential>] [-Database <String>] [-WhatIf]
 [-Confirm] [<CommonParameters>]
```

### Manual_Connection
```
Set-DSCPullServerAdminStatusReport -JobId <Guid> [-Id <Guid>] [-OperationType <String>] [-RefreshMode <String>]
 [-Status <String>] [-LCMVersion <String>] [-ReportFormatVersion <String>] [-ConfigurationVersion <String>]
 [-NodeName <String>] [-IPAddress <IPAddress[]>] [-StartTime <DateTime>] [-EndTime <DateTime>]
 [-LastModifiedTime <DateTime>] [-Errors <PSObject[]>] [-StatusData <PSObject[]>] [-RebootRequested <Boolean>]
 [-AdditionalData <PSObject[]>] [-Connection <DSCPullServerSQLConnection>] [-WhatIf] [-Confirm]
 [<CommonParameters>]
```

## DESCRIPTION
LCMv2 (WMF5+ / PowerShell 5+) pull clients send reports
to the Pull Server which stores their data in the StatusReport table.
This function will allow for manual Overwrites of status report properties
in the StatusReport table.

## EXAMPLES

### EXAMPLE 1
```
Set-DSCPullServerAdminStatusReport -JobId '80ee20f9-78df-480d-8175-9dd6cb09607a' -NodeName 'lcmclient01'
```

### EXAMPLE 2
```
Get-DSCPullServerAdminStatusReport -JobId '80ee20f9-78df-480d-8175-9dd6cb09607a' | Set-DSCPullServerAdminStatusReport -NodeName 'lcmclient01'
```

## PARAMETERS

### -InputObject
Pass in the statusreport object to be modified from the database.

```yaml
Type: DSCNodeStatusReport
Parameter Sets: InputObject_Connection, InputObject_SQL
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -JobId
Modify properties for the statusreport with specified JobId.

```yaml
Type: Guid
Parameter Sets: Manual_SQL, Manual_Connection
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Id
Set the Id property for the existing device.

```yaml
Type: Guid
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -OperationType
Set the OperationType property for the existing device.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -RefreshMode
Set the RefreshMode property for the existing device.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Status
Set the Status property for the existing device.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -LCMVersion
Set the LCMVersion property for the existing device.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ReportFormatVersion
Set the ReportFormatVersion property for the existing device.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ConfigurationVersion
Set the ConfigurationVersion property for the existing device.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -NodeName
Set the NodeName property for the existing device.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -IPAddress
Set the IPAddress property for the existing device.

```yaml
Type: IPAddress[]
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -StartTime
Set the StartTime property for the existing device.

```yaml
Type: DateTime
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -EndTime
Set the EndTime property for the existing device.

```yaml
Type: DateTime
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -LastModifiedTime
Set the LastModifiedTime property for the existing device.

```yaml
Type: DateTime
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Errors
Set the Errors property for the existing device.

```yaml
Type: PSObject[]
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -StatusData
Set the StatusData property for the existing device.

```yaml
Type: PSObject[]
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -RebootRequested
Set the RebootRequested property for the existing device.

```yaml
Type: Boolean
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -AdditionalData
Set the AdditionalData property for the existing device.

```yaml
Type: PSObject[]
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Connection
Accepts a specific Connection to be passed to target a specific database.
When not specified, the currently Active Connection from memory will be used
unless one off the parameters for ad-hoc connections (ESEFilePath, SQLServer)
is used in which case, an ad-hoc connection is created.

```yaml
Type: DSCPullServerSQLConnection
Parameter Sets: InputObject_Connection, Manual_Connection
Aliases:

Required: False
Position: Named
Default value: (Get-DSCPullServerAdminConnection -OnlyShowActive -Type SQL)
Accept pipeline input: False
Accept wildcard characters: False
```

### -SQLServer
Define the SQL Instance to use in an ad-hoc SQL connection.

```yaml
Type: String
Parameter Sets: InputObject_SQL, Manual_SQL
Aliases: SQLInstance

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Credential
Define the Credentials to use with an ad-hoc SQL connection.

```yaml
Type: PSCredential
Parameter Sets: InputObject_SQL, Manual_SQL
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Database
Define the database to use with an ad-hoc SQL connection.

```yaml
Type: String
Parameter Sets: InputObject_SQL, Manual_SQL
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -WhatIf
Shows what would happen if the cmdlet runs.
The cmdlet is not run.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: wi

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Confirm
Prompts you for confirmation before running the cmdlet.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: cf

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable.
For more information, see about_CommonParameters (http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS
