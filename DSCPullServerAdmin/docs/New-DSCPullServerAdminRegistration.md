---
external help file: DSCPullServerAdmin-help.xml
Module Name: DSCPullServerAdmin
online version:
schema: 2.0.0
---

# New-DSCPullServerAdminRegistration

## SYNOPSIS
Creates node registration entries (LCMv2) in a Pull Server Database.

## SYNTAX

### Connection (Default)
```
New-DSCPullServerAdminRegistration -AgentId <Guid> [-LCMVersion <String>] -NodeName <String>
 [-IPAddress <IPAddress[]>] [-ConfigurationNames <String[]>] [-Connection <DSCPullServerConnection>] [-WhatIf]
 [-Confirm] [<CommonParameters>]
```

### ESE
```
New-DSCPullServerAdminRegistration -AgentId <Guid> [-LCMVersion <String>] -NodeName <String>
 [-IPAddress <IPAddress[]>] [-ConfigurationNames <String[]>] -ESEFilePath <FileInfo> [-WhatIf] [-Confirm]
 [<CommonParameters>]
```

### MDB
```
New-DSCPullServerAdminRegistration -AgentId <Guid> [-LCMVersion <String>] -NodeName <String>
 [-IPAddress <IPAddress[]>] [-ConfigurationNames <String[]>] -MDBFilePath <FileInfo> [-WhatIf] [-Confirm]
 [<CommonParameters>]
```

### SQL
```
New-DSCPullServerAdminRegistration -AgentId <Guid> [-LCMVersion <String>] -NodeName <String>
 [-IPAddress <IPAddress[]>] [-ConfigurationNames <String[]>] -SQLServer <String> [-Credential <PSCredential>]
 [-Database <String>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
LCMv2 (WMF5+ / PowerShell 5+) pull clients send information
to the Pull Server which stores their data in the registrationdata table.
This function will allow for manual creation of registrations in the
registrationdata table and allows for multiple properties to be set.

## EXAMPLES

### EXAMPLE 1
```
New-DSCPullServerAdminRegistration -AgentId '80ee20f9-78df-480d-8175-9dd6cb09607a' -NodeName 'lcmclient01'
```

## PARAMETERS

### -AgentId
Set the AgentId property for the new device.

```yaml
Type: Guid
Parameter Sets: (All)
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -LCMVersion
Set the LCMVersion property for the new device.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: 2.0
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -NodeName
Set the NodeName property for the new device.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -IPAddress
Set the IPAddress property for the new device.

```yaml
Type: IPAddress[]
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -ConfigurationNames
Set the ConfigurationNames property for the new device.

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
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
