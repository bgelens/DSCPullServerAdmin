$here = $PSScriptRoot

$modulePath = "$here\..\..\.."
$moduleName = Split-Path -Path $modulePath -Leaf

InModuleScope $moduleName {
    Describe DSCNodeRegistration {
        Context 'Type creation' {
            It 'Has created a type named DSCNodeRegistration' {
                'DSCNodeRegistration' -as [Type] | Should -BeOfType [Type]
            }
        }

        Context 'Constructors' {
            It 'Has a default constructor' {
                $instance = [DSCNodeRegistration]::new()
                $instance | Should -Not -BeNullOrEmpty
                $instance.GetType().Name | Should -Be 'DSCNodeRegistration'
            }
        }

        Context 'SQL Methods' {
            $instance = [DSCNodeRegistration]::new()
            $instance.AgentId = [guid]::Empty

            $instance2 = [DSCNodeRegistration]::new()
            $instance2.AgentId = [guid]::Empty
            $instance2.ConfigurationNames = 'bla'

            It 'Should create a SQLUpdateQuery with empty ConfigurationName' {
                $instance.GetSQLUpdate() |
                    Should -Be "UPDATE RegistrationData Set ConfigurationNames = '[]',IPAddress = '',LCMVersion = '',NodeName = '' WHERE AgentId = '00000000-0000-0000-0000-000000000000'"
            }

            It 'Should create a SQLUpdateQuery with specified ConfigurationName' {
                $instance2.GetSQLUpdate() |
                    Should -Be "UPDATE RegistrationData Set ConfigurationNames = '[`"bla`"]',IPAddress = '',LCMVersion = '',NodeName = '' WHERE AgentId = '00000000-0000-0000-0000-000000000000'"
            }

            It 'Should create a SQLInsertQuery with empty ConfigurationName' {
                $instance.GetSQLInsert() |
                    Should -Be "INSERT INTO RegistrationData (AgentId,ConfigurationNames,IPAddress,LCMVersion,NodeName) VALUES ('00000000-0000-0000-0000-000000000000','[]','','','')"
            }

            It 'Should create a SQLInsertQuery with specified ConfigurationName' {
                $instance2.GetSQLInsert() |
                    Should -Be "INSERT INTO RegistrationData (AgentId,ConfigurationNames,IPAddress,LCMVersion,NodeName) VALUES ('00000000-0000-0000-0000-000000000000','[`"bla`"]','','','')"
            }

            It 'Should create a SQLDeleteQuery' {
                $instance.GetSQLDelete() |
                    Should -Be "DELETE FROM RegistrationData WHERE AgentId = '00000000-0000-0000-0000-000000000000'"
            }
        }
    }
}
