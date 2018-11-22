---
external help file: DSCPullServerAdmin-help.xml
Module Name: DSCPullServerAdmin
online version:
schema: 2.0.0
---

# New-DSCPullServerAdminDevice

## SYNOPSIS
Create device entries (LCMv1) in a Pull Server Database.

## SYNTAX

### Connection (Default)
```
New-DSCPullServerAdminDevice -ConfigurationID <Guid> -TargetName <String> [-ServerCheckSum <String>]
 [-TargetCheckSum <String>] [-NodeCompliant <Boolean>] [-LastComplianceTime <DateTime>]
 [-LastHeartbeatTime <DateTime>] [-Dirty <Boolean>] [-StatusCode <UInt32>]
 [-Connection <DSCPullServerConnection>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

### ESE
```
New-DSCPullServerAdminDevice -ConfigurationID <Guid> -TargetName <String> [-ServerCheckSum <String>]
 [-TargetCheckSum <String>] [-NodeCompliant <Boolean>] [-LastComplianceTime <DateTime>]
 [-LastHeartbeatTime <DateTime>] [-Dirty <Boolean>] [-StatusCode <UInt32>] -ESEFilePath <String> [-WhatIf]
 [-Confirm] [<CommonParameters>]
```

### SQL
```
New-DSCPullServerAdminDevice -ConfigurationID <Guid> -TargetName <String> [-ServerCheckSum <String>]
 [-TargetCheckSum <String>] [-NodeCompliant <Boolean>] [-LastComplianceTime <DateTime>]
 [-LastHeartbeatTime <DateTime>] [-Dirty <Boolean>] [-StatusCode <UInt32>] -SQLServer <String>
 [-Credential <PSCredential>] [-Database <String>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
LCMv1 (WMF4 / PowerShell 4.0) pull clients send information
to the Pull Server which stores their data in the devices table.
This function will allow for manual creation of devices in the
devices table and allows for multiple properties to be set.

## EXAMPLES

### EXAMPLE 1
```
New-DSCPullServerAdminDevice -ConfigurationID '80ee20f9-78df-480d-8175-9dd6cb09607a' -TargetName '192.168.0.1'
```

## PARAMETERS

### -ConfigurationID
Set the ConfigurationID property for the new device.

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

### -TargetName
Set the TargetName property for the new device.

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

### -ServerCheckSum
Set the ServerCheckSum property for the new device.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -TargetCheckSum
Set the TargetCheckSum property for the new device.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -NodeCompliant
Set the NodeCompliant property for the new device.

```yaml
Type: Boolean
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -LastComplianceTime
Set the LastComplianceTime property for the new device.

```yaml
Type: DateTime
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -LastHeartbeatTime
Set the LastHeartbeatTime property for the new device.

```yaml
Type: DateTime
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -Dirty
Set the Dirty property for the new device.

```yaml
Type: Boolean
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -StatusCode
Set the StatusCode property for the new device.

```yaml
Type: UInt32
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: 0
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
Type: String
Parameter Sets: ESE
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
