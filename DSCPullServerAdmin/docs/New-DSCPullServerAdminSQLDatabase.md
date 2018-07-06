---
external help file: DSCPullServerAdmin-help.xml
Module Name: DSCPullServerAdmin
online version:
schema: 2.0.0
---

# New-DSCPullServerAdminSQLDatabase

## SYNOPSIS
Creates a DSC Pull Server SQL Database.

## SYNTAX

```
New-DSCPullServerAdminSQLDatabase -SQLServer <String> [-Credential <PSCredential>] -Name <String> [-WhatIf]
 [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
Normally, the DSC Pull Server database is created when the first
interaction with the Pull Server takes place.
This function allows
for prestaging the database.

## EXAMPLES

### EXAMPLE 1
```
New-DSCPullServerAdminSQLDatabase -SQLServer sqlserver\instance -Name dscdb
```

## PARAMETERS

### -SQLServer
Define the SQL Instance where the database should be created.

```yaml
Type: String
Parameter Sets: (All)
Aliases: SQLInstance

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Credential
Define the Credentials to be used with the SQL Server connection.

```yaml
Type: PSCredential
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Name
Define the Database name to create.

```yaml
Type: String
Parameter Sets: (All)
Aliases: Database

Required: True
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
