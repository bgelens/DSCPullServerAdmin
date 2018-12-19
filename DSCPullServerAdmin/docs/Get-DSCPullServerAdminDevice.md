---
external help file: DSCPullServerAdmin-help.xml
Module Name: DSCPullServerAdmin
online version:
schema: 2.0.0
---

# Get-DSCPullServerAdminDevice

## SYNOPSIS
Get device entries (LCMv1) from a Pull Server Database.

## SYNTAX

### Connection (Default)
```
Get-DSCPullServerAdminDevice [-TargetName <String>] [-ConfigurationID <Guid>]
 [-Connection <DSCPullServerConnection>] [<CommonParameters>]
```

### ESE
```
Get-DSCPullServerAdminDevice [-TargetName <String>] [-ConfigurationID <Guid>] -ESEFilePath <FileInfo>
 [<CommonParameters>]
```

### MDB
```
Get-DSCPullServerAdminDevice [-TargetName <String>] [-ConfigurationID <Guid>] -MDBFilePath <FileInfo>
 [<CommonParameters>]
```

### SQL
```
Get-DSCPullServerAdminDevice [-TargetName <String>] [-ConfigurationID <Guid>] -SQLServer <String>
 [-Credential <PSCredential>] [-Database <String>] [<CommonParameters>]
```

## DESCRIPTION
LCMv1 (WMF4 / PowerShell 4.0) pull clients send information
to the Pull Server which stores their data in the devices table.
This function will return devices from the devices table and allows
for multiple types of filtering.

## EXAMPLES

### EXAMPLE 1
```
Get-DSCPullServerAdminDevice -TargetName '192.168.0.1'
```

### EXAMPLE 2
```
Get-DSCPullServerAdminDevice
```

## PARAMETERS

### -TargetName
Return the device with the specific TargetName.
Wildcards are supported for SQL and ESE connections but not for MDB connection.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: True
```

### -ConfigurationID
Return all devices with the same ConfigurationID.

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

### DSCDevice
## NOTES

## RELATED LINKS
