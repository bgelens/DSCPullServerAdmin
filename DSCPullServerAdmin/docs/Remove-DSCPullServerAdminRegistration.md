---
external help file: DSCPullServerAdmin-help.xml
Module Name: DSCPullServerAdmin
online version:
schema: 2.0.0
---

# Remove-DSCPullServerAdminRegistration

## SYNOPSIS
Removes node registration entries (LCMv2) from a Pull Server Database.

## SYNTAX

### InputObject_Connection (Default)
```
Remove-DSCPullServerAdminRegistration -InputObject <DSCNodeRegistration>
 [-Connection <DSCPullServerConnection>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

### InputObject_ESE
```
Remove-DSCPullServerAdminRegistration -InputObject <DSCNodeRegistration> -ESEFilePath <String> [-WhatIf]
 [-Confirm] [<CommonParameters>]
```

### InputObject_SQL
```
Remove-DSCPullServerAdminRegistration -InputObject <DSCNodeRegistration> -SQLServer <String>
 [-Credential <PSCredential>] [-Database <String>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

### Manual_ESE
```
Remove-DSCPullServerAdminRegistration -AgentId <Guid> -ESEFilePath <String> [-WhatIf] [-Confirm]
 [<CommonParameters>]
```

### Manual_SQL
```
Remove-DSCPullServerAdminRegistration -AgentId <Guid> -SQLServer <String> [-Credential <PSCredential>]
 [-Database <String>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

### Manual_Connection
```
Remove-DSCPullServerAdminRegistration -AgentId <Guid> [-Connection <DSCPullServerConnection>] [-WhatIf]
 [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
LCMv2 (WMF5+ / PowerShell 5+) pull clients send information
to the Pull Server which stores their data in the registrationdata table.
This function will remove node registrations from the registrationdata table.

## EXAMPLES

### EXAMPLE 1
```
Remove-DSCPullServerAdminRegistration -AgentId '80ee20f9-78df-480d-8175-9dd6cb09607a'
```

### EXAMPLE 2
```
Get-DSCPullServerAdminRegistration -TargetName '80ee20f9-78df-480d-8175-9dd6cb09607a' | Remove-DSCPullServerAdminRegistration
```

## PARAMETERS

### -InputObject
Pass in the registration object to be removed from the database.

```yaml
Type: DSCNodeRegistration
Parameter Sets: InputObject_Connection, InputObject_ESE, InputObject_SQL
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -AgentId
Define the AgentId of the registration to be removed from the database.

```yaml
Type: Guid
Parameter Sets: Manual_ESE, Manual_SQL, Manual_Connection
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
Type: DSCPullServerConnection
Parameter Sets: InputObject_Connection, Manual_Connection
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
Type: String
Parameter Sets: InputObject_ESE, Manual_ESE
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
