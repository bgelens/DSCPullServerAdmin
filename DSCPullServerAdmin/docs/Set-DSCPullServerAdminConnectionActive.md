---
external help file: DSCPullServerAdmin-help.xml
Module Name: DSCPullServerAdmin
online version:
schema: 2.0.0
---

# Set-DSCPullServerAdminConnectionActive

## SYNOPSIS
Set a connection that is stored in memory to be Active.

## SYNTAX

```
Set-DSCPullServerAdminConnectionActive [-Connection] <DSCPullServerConnection> [<CommonParameters>]
```

## DESCRIPTION
This function is used to set an existing connections for either SQL Databases
or EDB files to be the Active connection.

## EXAMPLES

### EXAMPLE 1
```
$connection = Get-DSCPullServerAdminConnection -Index 4
```

Set-DSCPullServerAdminConnectionActive -Connection $connection

## PARAMETERS

### -Connection
The connection object to be made active.

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

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see about_CommonParameters (http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS
