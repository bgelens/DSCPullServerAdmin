class DSCNodeStatusReport {
    [Guid] $JobId

    [Guid] $Id

    [string] $OperationType

    [string] $RefreshMode

    [string] $Status

    [string] $LCMVersion

    [string] $ReportFormatVersion

    [string] $ConfigurationVersion

    [string] $NodeName

    [IPAddress[]] $IPAddress

    [datetime] $StartTime

    [datetime] $EndTime

    [datetime] $LastModifiedTime # Only applicable for ESENT, Not present in SQL

    [PSObject[]] $Errors

    [PSObject[]] $StatusData

    [bool] $RebootRequested

    [PSObject[]] $AdditionalData

    DSCNodeStatusReport () {}

    DSCNodeStatusReport ([System.Data.Common.DbDataRecord] $Input) {
        for ($i = 0; $i -lt $Input.FieldCount; $i++) {
            $name = $Input.GetName($i)
            $data = $null
            switch ($name) {
                { $_ -in 'StatusData', 'Errors'} {
                    $data = (($Input[$i] | ConvertFrom-Json) | ConvertFrom-Json)
                }
                'AdditionalData' {
                    $data = ($Input[$i] | ConvertFrom-Json)
                }
                'IPAddress' {
                    $data = ($Input[$i] -split ',') -split ';' | ForEach-Object -Process {
                        if ($_ -ne [string]::Empty) {
                            $_
                        }
                    }
                }
                default {
                    $data = $Input[$i]
                }
            }
            if ($false -eq [string]::IsNullOrEmpty($data)) {
                $this."$name" = $data
            }
        }
    }

    [string] GetSQLUpdate () {
        $query = "UPDATE StatusReport Set {0} WHERE JobId = '{1}'" -f @(
            (($this | Get-Member -MemberType Property).Where{
                $_.Name -ne 'JobId'
            }.foreach{
                if ($_.Name -eq 'LastModifiedTime') {
                    # skip as missing in SQL table, only present in EDB
                } elseif ($_.Name -eq 'IPAddress') {
                    "$($_.Name) = '{0}'" -f ($this."$($_.Name)" -join ';')
                } elseif ($_.Name -in 'StatusData', 'Errors') {
                    "$($_.Name) = '[{0}]'" -f (($this."$($_.Name)" | ConvertTo-Json -Compress -Depth 100) | ConvertTo-Json -Compress)
                } elseif ($_.Name -eq 'AdditionalData') {
                    "$($_.Name) = '[{0}]'" -f ($this."$($_.Name)" | ConvertTo-Json -Compress -Depth 100)
                } else {
                    if ($_.Definition.Split(' ')[0] -eq 'datetime') {
                        if ($this."$($_.Name)".ToString('yyyy-MM-dd HH:mm:ss') -eq '0001-01-01 00:00:00') {
                            "$($_.Name) = NULL"
                        } else {
                            "$($_.Name) = '{0}'" -f $this."$($_.Name)".ToString('yyyy-MM-dd HH:mm:ss')
                        }
                    } else {
                        "$($_.Name) = '{0}'" -f $this."$($_.Name)"
                    }
                }
            } -join ','),
            $this.JobId
        )
        return $query
    }

    [string] GetSQLInsert () {
        $query = ("INSERT INTO StatusReport ({0}) VALUES ({1})" -f @(
            (($this | Get-Member -MemberType Property | Where-Object -FilterScript {$_.Name -ne 'LastModifiedTime'}).Name -join ','),
            (($this | Get-Member -MemberType Property).ForEach{
                if ($_.Name -eq 'LastModifiedTime') {
                    # skip as missing in SQL table, only present in EDB
                } elseif ($_.Name -eq 'IPAddress') {
                    "'{0}'" -f ($this."$($_.Name)" -join ';')
                } elseif ($_.Name -in 'StatusData', 'Errors') {
                    "'[{0}]'" -f (($this."$($_.Name)" | ConvertTo-Json -Compress -Depth 100) | ConvertTo-Json -Compress)
                } elseif ($_.Name -eq 'AdditionalData') {
                    "'{0}'" -f ($this."$($_.Name)" | ConvertTo-Json -Compress -Depth 100)
                } else {
                    if ($_.Definition.Split(' ')[0] -eq 'datetime') {
                        if ($this."$($_.Name)".ToString('yyyy-MM-dd HH:mm:ss') -eq '0001-01-01 00:00:00') {
                            'NULL'
                        } else {
                            "'{0}'" -f $this."$($_.Name)".ToString('yyyy-MM-dd HH:mm:ss')
                        }
                    } else {
                        "'{0}'" -f $this."$($_.Name)"
                    }
                }
            } -join ',')
        ))
        return $query
    }

    [string] GetSQLDelete () {
        return ("DELETE FROM StatusReport WHERE JobId = '{0}'" -f $this.JobId)
    }
}
