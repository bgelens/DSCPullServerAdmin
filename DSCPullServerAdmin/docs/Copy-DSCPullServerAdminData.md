---
external help file: DSCPullServerAdmin-help.xml
Module Name: DSCPullServerAdmin
online version:
schema: 2.0.0
---

# Copy-DSCPullServerAdminData

## SYNOPSIS
Copy data between 2 Database connections

## SYNTAX

```
Copy-DSCPullServerAdminData [-Connection1] <DSCPullServerConnection> [-Connection2] <DSCPullServerConnection>
 [-ObjectsToMigrate] <String[]> [-Force] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
This function allows for data to be copied over from
a connection to another connection.
This allows
a user to migrate over data from an ESENT type Pull Server to
a SQL type Pull Server, SQL to SQL type Pull Server, SQL to ESENT type
Pull Server and ESENT to ESENT Type Pull Server without loosing data.

## EXAMPLES

### EXAMPLE 1
```
$eseConnection = New-DSCPullServerAdminConnection -ESEFilePath C:\EDB\Devices.edb
```

$sqlConnection = New-DSCPullServerAdminConnection -SQLServer sqlserver\instance -Database dsc -Credential sa

Copy-DSCPullServerAdminData -ObjectsToMigrate Devices, RegistrationData, StatusReports -Connection1 $eseConnection -Connection2 $sqlConnection -Force

## PARAMETERS

### -Connection1
A specifically passed in Connection to migrate data out of.

```yaml
Type: DSCPullServerConnection
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Connection2
A specifically passed in Connection to migrate data in to.

```yaml
Type: DSCPullServerConnection
Parameter Sets: (All)
Aliases:

Required: True
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ObjectsToMigrate
Define the object types to migrate.
Defaults to Devices and RegistrationData.

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: True
Position: 3
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Force
When specified, existing records in the target database will be overwritten.
When not specified
existing data will not be overwritten and Warnings will be provided to inform
the user.

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
