class DSCBaseClass {
    hidden [DSCDatabaseTable] $TableName

    DSCBaseClass ([DSCDatabaseTable] $tableName) {
        $this.TableName = $tableName
    }

    hidden [string] GetKey () {
        $key = switch ($this.GetType().Name) {
            DSCDevice {
                'TargetName'
            }
            DSCNodeStatusReport {
                'JobId'
            }
            DSCNodeRegistration {
                'AgentId'
            }
        }
        return $key
    }

    hidden [string] GetExcludedProperties () {
        if ($this.GetType().Name -eq 'DSCDevice') {
            return 'Status'
        } elseif ($this.GetType().Name -eq 'DSCNodeStatusReport') {
            return 'LastModifiedTime'
        } else {
            return $null
        }
    }

    hidden [string] GetInsert ([bool] $isMDB) {
        $excludeProperties = $this.GetExcludedProperties()

        $query = ('INSERT INTO {0} ({1}) VALUES ({2})' -f @(
            $this.TableName,
            (($this | Get-Member -MemberType Property | Where-Object -FilterScript {$_.Name -notin $excludeProperties}).Name -join ','),
            (($this | Get-Member -MemberType Property).ForEach{
                if ($_.Name -in $excludeProperties) {
                    return
                } else {
                    if ($_.Name -eq 'ConfigurationNames') {
                        if ($this.ConfigurationNames.Count -ge 1) {
                            "'[`"{0}`"]'" -f ($this."$($_.Name)" -join '","')
                        } else {
                            "'[]'"
                        }
                    } elseif ($_.Name -eq 'IPAddress') {
                        "'{0}'" -f ($this."$($_.Name)" -join ';')
                    } elseif ($_.Name -in 'StatusData', 'Errors') {
                        "'[{0}]'" -f (($this."$($_.Name)" | ConvertTo-Json -Compress -Depth 100) | ConvertTo-Json -Compress)
                    } elseif ($_.Name -eq 'AdditionalData') {
                        "'{0}'" -f ($this."$($_.Name)" | ConvertTo-Json -Compress -Depth 100)
                    } elseif ($_.Definition.Split(' ')[0] -like '*datetime*' -and -not $null -eq $this."$($_.Name)") {
                        if ($this."$($_.Name)".ToString('yyyy-MM-dd HH:mm:ss') -eq '0001-01-01 00:00:00') {
                            'NULL'
                        } else {
                            "'{0}'" -f $this."$($_.Name)".ToString('yyyy-MM-dd HH:mm:ss')
                        }
                    } elseif ($_.Definition.Split(' ')[0] -like '*nullable*' -and $null -eq $this."$($_.Name)") {
                        'NULL'
                    } elseif ($_.Definition.Split(' ')[0] -like '*bool*' -and $isMDB) {
                        if ($this."$($_.Name)" -eq $false) {
                            "'{0}'" -f '0'
                        } else {
                            "'{0}'" -f '-1'
                        }
                    } else {
                        "'{0}'" -f $this."$($_.Name)"
                    }
                }
            } -join ',')
        ))
        return $query
    }

    hidden [string] GetUpdate ([bool] $isMDB) {
        $excludeProperties = $this.GetExcludedProperties()
        $key = $this.GetKey()
        $query = "UPDATE {0} Set {1} WHERE {2} = '{3}'" -f @(
            $this.TableName,
            (($this | Get-Member -MemberType Property).Where{
                $_.Name -ne $key
            }.foreach{
                if ($_.Name -in $excludeProperties) {
                    # skip
                } elseif ($_.Name -in 'StatusData', 'Errors') {
                    "$($_.Name) = '[{0}]'" -f (($this."$($_.Name)" | ConvertTo-Json -Compress -Depth 100) | ConvertTo-Json -Compress)
                } elseif ($_.Name -eq 'AdditionalData') {
                    "$($_.Name) = '[{0}]'" -f ($this."$($_.Name)" | ConvertTo-Json -Compress -Depth 100)
                } elseif ($_.Name -eq 'ConfigurationNames') {
                    if ($this.ConfigurationNames.Count -ge 1) {
                        "$($_.Name) = '[`"{0}`"]'" -f ($this."$($_.Name)" -join '","')
                    } else {
                        "$($_.Name) = '[]'"
                    }
                } elseif ($_.Name -eq 'IPAddress') {
                    "$($_.Name) = '{0}'" -f ($this."$($_.Name)" -join ';')
                } elseif ($_.Definition.Split(' ')[0] -like '*datetime*' -and -not $null -eq $this."$($_.Name)") {
                    if ($this."$($_.Name)".ToString('yyyy-MM-dd HH:mm:ss') -eq '0001-01-01 00:00:00') {
                        "$($_.Name) = NULL"
                    } else {
                        "$($_.Name) = '{0}'" -f $this."$($_.Name)".ToString('yyyy-MM-dd HH:mm:ss')
                    }
                } elseif ($_.Definition.Split(' ')[0] -like '*nullable*' -and $null -eq $this."$($_.Name)") {
                    "$($_.Name) = NULL"
                } elseif ($_.Definition.Split(' ')[0] -like '*bool*' -and $isMDB) {
                    if ($this."$($_.Name)" -eq $false) {
                        "$($_.Name) = '{0}'" -f '0'
                    } else {
                        "$($_.Name) = '{0}'" -f '-1'
                    }
                } else {
                    "$($_.Name) = '{0}'" -f $this."$($_.Name)"
                }
            } -join ','),
            $key,
            $this.$key
        )
        return $query
    }

    hidden [string] GetDelete () {
        $key = $this.GetKey()
        return ("DELETE FROM {0} WHERE {1} = '{2}'" -f $this.TableName, $key, $this.$key)
    }

    [string] GetSQLDelete () {
        return $this.GetDelete()
    }

    [string] GetMDBDelete () {
        return $this.GetDelete()
    }

    [string] GetSQLInsert () {
        return $this.GetInsert($false)
    }

    [string] GetMDBInsert () {
        return $this.GetInsert($true)
    }

    [string] GetSQLUpdate () {
        return $this.GetUpdate($false)
    }

    [string] GetMDBUpdate () {
        return $this.GetUpdate($true)
    }
}
