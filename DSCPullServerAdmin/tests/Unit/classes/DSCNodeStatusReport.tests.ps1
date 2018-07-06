$here = $PSScriptRoot

$modulePath = "$here\..\..\.."
$moduleName = Split-Path -Path $modulePath -Leaf

InModuleScope $moduleName {
    Describe DSCNodeStatusReport {
        Context 'Type creation' {
            It 'Has created a type named DSCNodeStatusReport' {
                'DSCNodeStatusReport' -as [Type] | Should -BeOfType [Type]
            }
        }

        Context 'Constructors' {
            It 'Has a default constructor' {
                $instance = [DSCNodeStatusReport]::new()
                $instance | Should -Not -BeNullOrEmpty
                $instance.GetType().Name | Should -Be 'DSCNodeStatusReport'
            }
        }

        Context 'SQL Methods' {
            $instance = [DSCNodeStatusReport]::new()
            $instance.Id = [guid]::Empty
            $instance.JobId = [guid]::Empty

            $instance2 = [DSCNodeStatusReport]::new()
            $instance2.Id = [guid]::Empty
            $instance2.JobId = [guid]::Empty
            $instance2.StartTime = [datetime]::MinValue
            $instance2.EndTime = [datetime]::MaxValue
            $instance2.LastModifiedTime = [datetime]::Now # should not be present

            $instance3 = [DSCNodeStatusReport]::new()
            $instance3.Id = [guid]::Empty
            $instance3.JobId = [guid]::Empty
            $instance3.IPAddress = @(
                [ipaddress]::Parse('192.168.0.1'),
                [ipaddress]::Parse('127.0.0.1')
            )

            $instance4 = [DSCNodeStatusReport]::new()
            $instance4.Id = [guid]::Empty
            $instance4.JobId = [guid]::Empty
            $instance4.AdditionalData = @(
                [pscustomobject]@{
                    Key = 'OSVersion'
                    Value = '{"VersionString":"Microsoft Windows NT 10.0.14393.0","ServicePack":"","Platform":"Win32NT"}'
                },
                [pscustomobject]@{
                    Key = 'PSVersion'
                    Value = '{"CLRVersion":"4.0.30319.42000","PSVersion":"5.1.14393.1884","BuildVersion":"10.0.14393.1884"}'
                }
            )
            $instance4.StatusData = @(
                [pscustomobject]@{
                    Status = 'Success'
                    LCMVersion = '2.0'
                    Type = 'Initial'
                    HostName = 'PullClient'
                    RebootRequested = $false
                    JobID = [guid]::Empty
                    Mode = 'Pull'
                }
            )

            It 'Should create a SQLUpdateQuery without optional properties' {
                $instance.GetSQLUpdate() |
                    Should -Be "UPDATE StatusReport Set AdditionalData = '[]',ConfigurationVersion = '',EndTime = NULL,Errors = '[]',Id = '00000000-0000-0000-0000-000000000000',IPAddress = '',LCMVersion = '',NodeName = '',OperationType = '',RebootRequested = 'False',RefreshMode = '',ReportFormatVersion = '',StartTime = NULL,Status = '',StatusData = '[]' WHERE JobId = '00000000-0000-0000-0000-000000000000'"
            }

            It 'Should create a SQLInsertQuery without optional properties' {
                $instance.GetSQLInsert() |
                    Should -Be "INSERT INTO StatusReport (AdditionalData,ConfigurationVersion,EndTime,Errors,Id,IPAddress,JobId,LCMVersion,NodeName,OperationType,RebootRequested,RefreshMode,ReportFormatVersion,StartTime,Status,StatusData) VALUES ('','',NULL,'[]','00000000-0000-0000-0000-000000000000','','00000000-0000-0000-0000-000000000000','','','','False','','',NULL,'','[]')"
            }

            It 'Should create a SQLUpdateQuery with datetime properties set and not have LastModifiedTime' {
                $result = $instance2.GetSQLUpdate()
                $result | Should -Be "UPDATE StatusReport Set AdditionalData = '[]',ConfigurationVersion = '',EndTime = '9999-12-31 23:59:59',Errors = '[]',Id = '00000000-0000-0000-0000-000000000000',IPAddress = '',LCMVersion = '',NodeName = '',OperationType = '',RebootRequested = 'False',RefreshMode = '',ReportFormatVersion = '',StartTime = NULL,Status = '',StatusData = '[]' WHERE JobId = '00000000-0000-0000-0000-000000000000'"
                $result | Should -not -Match 'LastModifiedTime'
            }


            It 'Should create a SQLInsertQuery with datetime properties set and not have LastModifiedTime' {
                $result = $instance2.GetSQLInsert()
                $result | Should -Be "INSERT INTO StatusReport (AdditionalData,ConfigurationVersion,EndTime,Errors,Id,IPAddress,JobId,LCMVersion,NodeName,OperationType,RebootRequested,RefreshMode,ReportFormatVersion,StartTime,Status,StatusData) VALUES ('','','9999-12-31 23:59:59','[]','00000000-0000-0000-0000-000000000000','','00000000-0000-0000-0000-000000000000','','','','False','','',NULL,'','[]')"
                $result | Should -not -Match 'LastModifiedTime'
            }

            It 'Should create a SQLUpdateQuery with ipaddress property' {
                $instance3.GetSQLUpdate() |
                    Should -Be "UPDATE StatusReport Set AdditionalData = '[]',ConfigurationVersion = '',EndTime = NULL,Errors = '[]',Id = '00000000-0000-0000-0000-000000000000',IPAddress = '192.168.0.1;127.0.0.1',LCMVersion = '',NodeName = '',OperationType = '',RebootRequested = 'False',RefreshMode = '',ReportFormatVersion = '',StartTime = NULL,Status = '',StatusData = '[]' WHERE JobId = '00000000-0000-0000-0000-000000000000'"
            }


            It 'Should create a SQLInsertQuery with ipaddress property' {
                $instance3.GetSQLInsert() |
                    Should -Be "INSERT INTO StatusReport (AdditionalData,ConfigurationVersion,EndTime,Errors,Id,IPAddress,JobId,LCMVersion,NodeName,OperationType,RebootRequested,RefreshMode,ReportFormatVersion,StartTime,Status,StatusData) VALUES ('','',NULL,'[]','00000000-0000-0000-0000-000000000000','192.168.0.1;127.0.0.1','00000000-0000-0000-0000-000000000000','','','','False','','',NULL,'','[]')"
            }

            It 'Should create a SQLUpdateQuery with StatusData and AdditionalData properties' {
                $instance4.GetSQLUpdate() |
                    Should -Be @'
UPDATE StatusReport Set AdditionalData = '[[{"Key":"OSVersion","Value":"{\"VersionString\":\"Microsoft Windows NT 10.0.14393.0\",\"ServicePack\":\"\",\"Platform\":\"Win32NT\"}"},{"Key":"PSVersion","Value":"{\"CLRVersion\":\"4.0.30319.42000\",\"PSVersion\":\"5.1.14393.1884\",\"BuildVersion\":\"10.0.14393.1884\"}"}]]',ConfigurationVersion = '',EndTime = NULL,Errors = '[]',Id = '00000000-0000-0000-0000-000000000000',IPAddress = '',LCMVersion = '',NodeName = '',OperationType = '',RebootRequested = 'False',RefreshMode = '',ReportFormatVersion = '',StartTime = NULL,Status = '',StatusData = '["{\"Status\":\"Success\",\"LCMVersion\":\"2.0\",\"Type\":\"Initial\",\"HostName\":\"PullClient\",\"RebootRequested\":false,\"JobID\":\"00000000-0000-0000-0000-000000000000\",\"Mode\":\"Pull\"}"]' WHERE JobId = '00000000-0000-0000-0000-000000000000'
'@
            }


            It 'Should create a SQLInsertQuery with StatusData and AdditionalData properties' {
                $instance4.GetSQLInsert() |
                    Should -Be @'
INSERT INTO StatusReport (AdditionalData,ConfigurationVersion,EndTime,Errors,Id,IPAddress,JobId,LCMVersion,NodeName,OperationType,RebootRequested,RefreshMode,ReportFormatVersion,StartTime,Status,StatusData) VALUES ('[{"Key":"OSVersion","Value":"{\"VersionString\":\"Microsoft Windows NT 10.0.14393.0\",\"ServicePack\":\"\",\"Platform\":\"Win32NT\"}"},{"Key":"PSVersion","Value":"{\"CLRVersion\":\"4.0.30319.42000\",\"PSVersion\":\"5.1.14393.1884\",\"BuildVersion\":\"10.0.14393.1884\"}"}]','',NULL,'[]','00000000-0000-0000-0000-000000000000','','00000000-0000-0000-0000-000000000000','','','','False','','',NULL,'','["{\"Status\":\"Success\",\"LCMVersion\":\"2.0\",\"Type\":\"Initial\",\"HostName\":\"PullClient\",\"RebootRequested\":false,\"JobID\":\"00000000-0000-0000-0000-000000000000\",\"Mode\":\"Pull\"}"]')
'@
            }

            It 'Should create a SQLDeleteQuery' {
                $instance.GetSQLDelete() |
                    Should -Be "DELETE FROM StatusReport WHERE JobId = '00000000-0000-0000-0000-000000000000'"
            }
        }
    }
}
