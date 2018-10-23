---
external help file: DSCPullServerAdmin-help.xml
Module Name: DSCPullServerAdmin
online version:
schema: 2.0.0
---

# Remove-DSCPullServerAdminConnection

## SYNOPSIS
Removes stored ESE and SQL connections from memory.

## SYNTAX

```
Remove-DSCPullServerAdminConnection [-Connection] <DSCPullServerConnection> [<CommonParameters>]
```

## DESCRIPTION
Connection objects created by New-DSCPullServerAdminConnection
are stored in memory.
This allows for multiple connections to
exist simultaneously in the same session.
When a connection can
be disposed, this function allows you to remove it.

## EXAMPLES

### EXAMPLE 1
```
Get-DSCPullServerAdminConnection -Index 4 | Remove-DSCPullServerAdminConnection
```

## PARAMETERS

### -Connection
The connection object to be removed from memory.

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
