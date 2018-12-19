---
external help file: DSCPullServerAdmin-help.xml
Module Name: DSCPullServerAdmin
online version:
schema: 2.0.0
---

# Get-DSCPullServerAdminStatusReport

## SYNOPSIS
Get status report entries (LCMv2) from a Pull Server Database.

## SYNTAX

### Connection (Default)
```
Get-DSCPullServerAdminStatusReport [-AgentId <Guid>] [-NodeName <String>] [-JobId <Guid>]
 [-FromStartTime <DateTime>] [-ToStartTime <DateTime>] [-All] [-Top <UInt16>] [-OperationType <String>]
 [-Connection <DSCPullServerConnection>] [<CommonParameters>]
```

### ESE
```
Get-DSCPullServerAdminStatusReport [-AgentId <Guid>] [-NodeName <String>] [-JobId <Guid>]
 [-FromStartTime <DateTime>] [-ToStartTime <DateTime>] [-All] [-Top <UInt16>] [-OperationType <String>]
 -ESEFilePath <FileInfo> [<CommonParameters>]
```

### MDB
```
Get-DSCPullServerAdminStatusReport [-AgentId <Guid>] [-NodeName <String>] [-JobId <Guid>]
 [-FromStartTime <DateTime>] [-ToStartTime <DateTime>] [-All] [-Top <UInt16>] [-OperationType <String>]
 -MDBFilePath <FileInfo> [<CommonParameters>]
```

### SQL
```
Get-DSCPullServerAdminStatusReport [-AgentId <Guid>] [-NodeName <String>] [-JobId <Guid>]
 [-FromStartTime <DateTime>] [-ToStartTime <DateTime>] [-All] [-Top <UInt16>] [-OperationType <String>]
 -SQLServer <String> [-Credential <PSCredential>] [-Database <String>] [<CommonParameters>]
```

## DESCRIPTION
LCMv2 (WMF5+ / PowerShell 5+) pull clients send reports
to the Pull Server which stores their data in the StatusReport table.
This function will return status reports from the StatusReport table
and allows for multiple types of filtering.

## EXAMPLES

### EXAMPLE 1
```
Get-DSCPullServerAdminStatusReport -JobId '80ee20f9-78df-480d-8175-9dd6cb09607a'
```

## PARAMETERS

### -AgentId
Return the reports with the specific AgentId.

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

### -NodeName
Return the reports with the specific NodeName.
Wildcards are supported for SQL and ESE connections but not for MDB connection.

```yaml
Type: String
Parameter Sets: (All)
Aliases: Name

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: True
```

### -JobId
Return the reports with the specific JobId (Key).

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

### -FromStartTime
Return the reports which start from the specific FromStartTime.

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

### -ToStartTime
Return the reports which start no later than the specific ToStartTime.

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

### -All
Return all reports that correspond to specified filters (overwrites Top parameter).
SQL Only.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -Top
Return number of reports that correspond to specified filters.
SQL Only.

```yaml
Type: UInt16
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: 5
Accept pipeline input: False
Accept wildcard characters: False
```

### -OperationType
Return the reports which have the specified OperationType.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: All
Accept pipeline input: False
Accept wildcard characters: False
```

### -Connection
Accepts a specific Connection to be passed to target a specific database.
When not specified, the currently Active Connection from memory will be used
unless one off the parameters for ad-hoc connections (ESEFilePath, SQLServer)
is used in which case, an ad-hoc connection is created.

```yaml
Type: DSCPullServerConnection
Parameter Sets: Connection
Aliases:

Required: False
Position: Named
Default value: (Get-DSCPullServerAdminConnection -OnlyShowActive)
Accept pipeline input: False
Accept wildcard characters: False
```

### -ESEFilePath
Define the EDB file path to use an ad-hoc ESE connection.

```yaml
Type: FileInfo
Parameter Sets: ESE
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -MDBFilePath
Define the MDB file path to use an ad-hoc MDB connection.

```yaml
Type: FileInfo
Parameter Sets: MDB
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -SQLServer
Define the SQL Instance to use in an ad-hoc SQL connection.

```yaml
Type: String
Parameter Sets: SQL
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
Parameter Sets: SQL
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
Parameter Sets: SQL
Aliases:

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

### DSCNodeStatusReport
## NOTES

## RELATED LINKS
