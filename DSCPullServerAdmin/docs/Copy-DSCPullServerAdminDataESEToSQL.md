---
external help file: DSCPullServerAdmin-help.xml
Module Name: DSCPullServerAdmin
online version:
schema: 2.0.0
---

# Copy-DSCPullServerAdminDataESEToSQL

## SYNOPSIS
Copy data from EDB to SQL.

## SYNTAX

```
Copy-DSCPullServerAdminDataESEToSQL [-ESEConnection] <DSCPullServerESEConnection>
 [-SQLConnection] <DSCPullServerSQLConnection> [[-ObjectsToMigrate] <String[]>] [-Force] [-WhatIf] [-Confirm]
 [<CommonParameters>]
```

## DESCRIPTION
This function allows for data to be copied over from
an ESE (edb) connection to a SQL connection.
This allows
a user to migrate over from an ESENT type Pull Server to
a SQL type Pull Server without loosing data.

## EXAMPLES

### EXAMPLE 1
```
$eseConnection = New-DSCPullServerAdminConnection -ESEFilePath C:\EDB\Devices.edb
```

$sqlConnection = New-DSCPullServerAdminSQLDatabase -SQLServer sqlserver\instance -Name dsc -Credential sa

Copy-DSCPullServerAdminDataESEToSQL -ObjectsToMigrate Devices, RegistrationData, StatusReports -Force

## PARAMETERS

### -ESEConnection
A specifically passed in ESE connection to migrate data out of.

```yaml
Type: DSCPullServerESEConnection
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -SQLConnection
A specifically passed in SQL connection to migrate data in to.

```yaml
Type: DSCPullServerSQLConnection
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

Required: False
Position: 3
Default value: @('Devices', 'RegistrationData')
Accept pipeline input: False
Accept wildcard characters: False
```

### -Force
When specified, existing records in SQL will be overwritten.
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
