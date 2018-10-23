---
external help file: DSCPullServerAdmin-help.xml
Module Name: DSCPullServerAdmin
online version:
schema: 2.0.0
---

# Remove-DSCPullServerAdminDevice

## SYNOPSIS
Removes device entries (LCMv1) from a Pull Server Database.

## SYNTAX

### InputObject_Connection (Default)
```
Remove-DSCPullServerAdminDevice -InputObject <DSCDevice> [-Connection <DSCPullServerSQLConnection>] [-WhatIf]
 [-Confirm] [<CommonParameters>]
```

### InputObject_SQL
```
Remove-DSCPullServerAdminDevice -InputObject <DSCDevice> -SQLServer <String> [-Credential <PSCredential>]
 [-Database <String>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

### Manual_SQL
```
Remove-DSCPullServerAdminDevice -TargetName <String> -SQLServer <String> [-Credential <PSCredential>]
 [-Database <String>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

### Manual_Connection
```
Remove-DSCPullServerAdminDevice -TargetName <String> [-Connection <DSCPullServerSQLConnection>] [-WhatIf]
 [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
LCMv1 (WMF4 / PowerShell 4.0) pull clients send information
to the Pull Server which stores their data in the devices table.
This function will remove devices from the devices table.

## EXAMPLES

### EXAMPLE 1
```
Remove-DSCPullServerAdminDevice -TargetName '192.168.0.1'
```

### EXAMPLE 2
```
Get-DSCPullServerAdminDevice -TargetName '192.168.0.1' | Remove-DSCPullServerAdminDevice
```

## PARAMETERS

### -InputObject
Pass in the device object to be removed from the database.

```yaml
Type: DSCDevice
Parameter Sets: InputObject_Connection, InputObject_SQL
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -TargetName
Define the TargetName of the device to be removed from the database.

```yaml
Type: String
Parameter Sets: Manual_SQL, Manual_Connection
Aliases:

Required: True
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
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see about_CommonParameters (http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS
