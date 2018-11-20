---
external help file: DSCPullServerAdmin-help.xml
Module Name: DSCPullServerAdmin
online version:
schema: 2.0.0
---

# Get-DSCPullServerAdminConnection

## SYNOPSIS
Get stored ESE and SQL connections from memory.

## SYNTAX

```
Get-DSCPullServerAdminConnection [[-Type] <DSCPullServerConnectionType>] [-OnlyShowActive] [[-Index] <UInt16>]
 [<CommonParameters>]
```

## DESCRIPTION
Connection objects created by New-DSCPullServerAdminConnection
are stored in memory.
This allows for multiple connections to
exist simultaneously in the same session.
This function will
return the existing connections and allows for multiple types of
filtering.

## EXAMPLES

### EXAMPLE 1
```
Get-DSCPullServerAdminConnection -OnlyShowActive
```

### EXAMPLE 2
```
Get-DSCPullServerAdminConnection
```

## PARAMETERS

### -Type
Filter output on Connection type.

```yaml
Type: DSCPullServerConnectionType
Parameter Sets: (All)
Aliases:
Accepted values: SQL, ESE

Required: False
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -OnlyShowActive
Only return the current Active connection.

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

### -Index
Return a specific Connection based on it's index number.

```yaml
Type: UInt16
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: 0
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable.
For more information, see about_CommonParameters (http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### DSCPullServerSQLConnection

### DSCPullServerESEConnection

## NOTES

## RELATED LINKS
