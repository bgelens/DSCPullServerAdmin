class DSCNodeStatusReport : DSCBaseClass {
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

    [nullable[datetime]] $StartTime

    [nullable[datetime]] $EndTime

    [nullable[datetime]] $LastModifiedTime # Only applicable for ESENT, Not present in SQL

    [PSObject[]] $Errors

    [PSObject[]] $StatusData

    [bool] $RebootRequested

    [PSObject[]] $AdditionalData

    DSCNodeStatusReport () : base([DSCDatabaseTable]::StatusReport) { }

    DSCNodeStatusReport ([System.Data.Common.DbDataRecord] $Input) : base([DSCDatabaseTable]::StatusReport) {
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
}
