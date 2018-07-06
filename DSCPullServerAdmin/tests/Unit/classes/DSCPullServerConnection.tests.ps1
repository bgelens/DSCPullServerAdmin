$here = $PSScriptRoot

$modulePath = "$here\..\..\.."
$moduleName = Split-Path -Path $modulePath -Leaf

InModuleScope $moduleName {
    Describe DSCPullServerConnection {
        Context 'Type creation' {
            It 'Has created a type named DSCPullServerConnection' {
                'DSCPullServerConnection' -as [Type] | Should -BeOfType [Type]
            }
        }

        Context 'Constructors' {
            It 'Does not have a default constructor' {
                { [DSCPullServerConnection]::new() } |
                    Should -Throw 'Cannot find an overload for "new" and the argument count: "0".'
            }
        }
    }
}
