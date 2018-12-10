$here = $PSScriptRoot

$modulePath = "$here\..\..\.."
$moduleName = Split-Path -Path $modulePath -Leaf

InModuleScope $moduleName {
    Describe DSCDevice {
        Context 'Type creation' {
            It 'Has created a type named DSCDevice' {
                'DSCDevice' -as [Type] | Should -BeOfType [Type]
            }
        }

        Context 'Constructors' {
            It 'Has a default constructor' {
                $instance = [DSCDevice]::new()
                $instance | Should -Not -BeNullOrEmpty
                $instance.GetType().Name | Should -Be 'DSCDevice'
            }
        }

        Context 'StatusCode to Status' {
            $deviceStatusCodeMap = @{
                0 = 'Configuration was applied successfully'
                1 = 'Download Manager initialization failure'
                2 = 'Get configuration command failure'
                3 = 'Unexpected get configuration response from pull server'
                4 = 'Configuration checksum file read failure'
                5 = 'Configuration checksum validation failure'
                6 = 'Invalid configuration file'
                7 = 'Available modules check failure'
                8 = 'Invalid configuration Id In meta-configuration'
                9 = 'Invalid DownloadManager CustomData in meta-configuration'
                10 = 'Get module command failure'
                11 = 'Get Module Invalid Output'
                12 = 'Module checksum file not found'
                13 = 'Invalid module file'
                14 = 'Module checksum validation failure'
                15 = 'Module extraction failed'
                16 = 'Module validation failed'
                17 = 'Downloaded module is invalid'
                18 = 'Configuration file not found'
                19 = 'Multiple configuration files found'
                20 = 'Configuration checksum file not found'
                21 = 'Module not found'
                22 = 'Invalid module version format'
                23 = 'Invalid configuration Id format'
                24 = 'Get Action command failed'
                25 = 'Invalid checksum algorithm'
                26 = 'Get Lcm Update command failed'
                27 = 'Unexpected Get Lcm Update response from pull server'
                28 = 'Invalid Refresh Mode in meta-configuration'
                29 = 'Invalid Debug Mode in meta-configuration'
            }

            It 'Should have correct friendly Status based on StatusCode' {
                foreach ($c in $deviceStatusCodeMap.Keys) {
                    $instance = [DSCDevice]::new()
                    $instance.StatusCode = $c
                    $instance.Status | Should -Be $deviceStatusCodeMap[$c]
                }
            }
        }

        $instance = [DSCDevice]::new()
        $instance.TargetName = 'bogusTargetName'
        $instance.ConfigurationID = [guid]::Empty
        $instance.LastComplianceTime = [datetime]::MinValue
        $instance.LastHeartbeatTime = [datetime]::MaxValue
        $instance.NodeCompliant = $false
        $instance.Dirty = $false

        $instance2 = [DSCDevice]::new()
        $instance2.TargetName = 'bogusTargetName'
        $instance2.ConfigurationID = [guid]::Empty
        $instance2.NodeCompliant = $true
        $instance2.Dirty = $true

        Context 'SQL Methods' {
            It 'Should create a SQLUpdateQuery with LastComplianceTime expected to be NULL, LastHeartbeatTime expected to be 9999-12-31 23:59:59, Dirty expected to be False and NodeCompliant expected to be False' {
                $instance.GetSQLUpdate() |
                    Should -Be "UPDATE Devices Set ConfigurationID = '00000000-0000-0000-0000-000000000000',Dirty = 'False',LastComplianceTime = NULL,LastHeartbeatTime = '9999-12-31 23:59:59',NodeCompliant = 'False',ServerCheckSum = '',StatusCode = '0',TargetCheckSum = '' WHERE TargetName = 'bogusTargetName'"
            }

            It 'Should create a SQLUpdateQuery with LastComplianceTime expected to be NULL, LastHeartbeatTime expected to be NULL, Dirty expected to be True and NodeCompliant expected to be True' {
                $instance2.GetSQLUpdate() |
                    Should -Be "UPDATE Devices Set ConfigurationID = '00000000-0000-0000-0000-000000000000',Dirty = 'True',LastComplianceTime = NULL,LastHeartbeatTime = NULL,NodeCompliant = 'True',ServerCheckSum = '',StatusCode = '0',TargetCheckSum = '' WHERE TargetName = 'bogusTargetName'"
            }

            It 'Should create a SQLInsertQuery with LastComplianceTime expected to be NULL, LastHeartbeatTime expected to be 9999-12-31 23:59:59, Dirty expected to be False and NodeCompliant expected to be False' {
                $instance.GetSQLInsert() |
                    Should -Be "INSERT INTO Devices (ConfigurationID,Dirty,LastComplianceTime,LastHeartbeatTime,NodeCompliant,ServerCheckSum,StatusCode,TargetCheckSum,TargetName) VALUES ('00000000-0000-0000-0000-000000000000','False',NULL,'9999-12-31 23:59:59','False','','0','','bogusTargetName')"
            }

            It 'Should create a SQLInsertQuery with LastComplianceTime expected to be NULL, LastHeartbeatTime expected to be NULL, Dirty expected to be True and NodeCompliant expected to be True' {
                $instance2.GetSQLInsert() |
                    Should -Be "INSERT INTO Devices (ConfigurationID,Dirty,LastComplianceTime,LastHeartbeatTime,NodeCompliant,ServerCheckSum,StatusCode,TargetCheckSum,TargetName) VALUES ('00000000-0000-0000-0000-000000000000','True',NULL,NULL,'True','','0','','bogusTargetName')"
            }

            It 'Should create a SQLDeleteQuery' {
                $instance.GetSQLDelete() |
                    Should -Be "DELETE FROM Devices WHERE TargetName = 'bogusTargetName'"
            }
        }

        Context 'MDB Methods' {
            It 'Should create a MDBUpdateQuery with LastComplianceTime expected to be NULL, LastHeartbeatTime expected to be 9999-12-31 23:59:59, Dirty expected to be 0 and NodeCompliant expected to be 0' {
                $instance.GetMDBUpdate() |
                    Should -Be "UPDATE Devices Set ConfigurationID = '00000000-0000-0000-0000-000000000000',Dirty = '0',LastComplianceTime = NULL,LastHeartbeatTime = '9999-12-31 23:59:59',NodeCompliant = '0',ServerCheckSum = '',StatusCode = '0',TargetCheckSum = '' WHERE TargetName = 'bogusTargetName'"
            }

            It 'Should create a MDBUpdateQuery with LastComplianceTime expected to be NULL, LastHeartbeatTime expected to be NULL, Dirty expected to be -1 and NodeCompliant expected to be -1' {
                $instance2.GetMDBUpdate() |
                    Should -Be "UPDATE Devices Set ConfigurationID = '00000000-0000-0000-0000-000000000000',Dirty = '-1',LastComplianceTime = NULL,LastHeartbeatTime = NULL,NodeCompliant = '-1',ServerCheckSum = '',StatusCode = '0',TargetCheckSum = '' WHERE TargetName = 'bogusTargetName'"
            }

            It 'Should create a MDBInsertQuery with LastComplianceTime expected to be NULL, LastHeartbeatTime expected to be 9999-12-31 23:59:59, Dirty expected to be 0 and NodeCompliant expected to be 0' {
                $instance.GetMDBInsert() |
                    Should -Be "INSERT INTO Devices (ConfigurationID,Dirty,LastComplianceTime,LastHeartbeatTime,NodeCompliant,ServerCheckSum,StatusCode,TargetCheckSum,TargetName) VALUES ('00000000-0000-0000-0000-000000000000','0',NULL,'9999-12-31 23:59:59','0','','0','','bogusTargetName')"
            }

            It 'Should create a MDBInsertQuery with LastComplianceTime expected to be NULL, LastHeartbeatTime expected to be NULL, Dirty expected to be -1 and NodeCompliant expected to be -1' {
                $instance2.GetMDBInsert() |
                    Should -Be "INSERT INTO Devices (ConfigurationID,Dirty,LastComplianceTime,LastHeartbeatTime,NodeCompliant,ServerCheckSum,StatusCode,TargetCheckSum,TargetName) VALUES ('00000000-0000-0000-0000-000000000000','-1',NULL,NULL,'-1','','0','','bogusTargetName')"
            }

            It 'Should create a MDBDeleteQuery' {
                $instance.GetMDBDelete() |
                    Should -Be "DELETE FROM Devices WHERE TargetName = 'bogusTargetName'"
            }
        }
    }
}
