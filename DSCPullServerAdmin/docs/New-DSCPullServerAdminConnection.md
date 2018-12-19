---
external help file: DSCPullServerAdmin-help.xml
Module Name: DSCPullServerAdmin
online version:
schema: 2.0.0
---

# New-DSCPullServerAdminConnection

## SYNOPSIS
Create a new connection with either a SQL Database or EDB file.

## SYNTAX

### SQL (Default)
```
New-DSCPullServerAdminConnection [-SQLServer <String>] [-Credential <PSCredential>] [-Database <String>]
 [-DontStore] [<CommonParameters>]
```

### ESE
```
New-DSCPullServerAdminConnection -ESEFilePath <FileInfo> [-DontStore] [<CommonParameters>]
```

### MDB
```
New-DSCPullServerAdminConnection -MDBFilePath <FileInfo> [-DontStore] [<CommonParameters>]
```

## DESCRIPTION
This function is used to create new connections for either SQL Databases
or EDB files that are re-used for multiple tasks.
More than one connection can
be created in a PowerShell session.
By default, connections are stored in memory
and are visible via the Get-DSCPullServerAdminConnection function.
Connections can be passed to other functions via parameter binding.
The default connection is used by default for all other functions.
The default
connection can be modified with the Set-DSCPullServerAdminConnectionActive
function.

## EXAMPLES

### EXAMPLE 1
```
New-DSCPullServerAdminConnection -ESEFilePath C:\Users\EDB\Devices.edb
```

### EXAMPLE 2
```
$sqlCredential = Get-Credential
```

New-DSCPullServerAdminConnection -SQLServer sqlserver\instance -Database dscpulldb -Credential $sqlCredential

## PARAMETERS

### -ESEFilePath
Specifies the path to the EDB file to be used for the connection.

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
Specifies the path to the MDB file to be used for the connection.

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
Specifies the SQL Instance to connect to for the connection.

```yaml
Type: String
Parameter Sets: SQL
Aliases: SQLInstance

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Credential
Specifies optional Credentials to use when connecting to the SQL Instance.

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
Specifies the Database name to use for the SQL connection.

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

### -DontStore
When specified, the connection will not be stored in memory.

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

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable.
For more information, see about_CommonParameters (http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### DSCPullServerSQLConnection
### DSCPullServerESEConnection
## NOTES

## RELATED LINKS
