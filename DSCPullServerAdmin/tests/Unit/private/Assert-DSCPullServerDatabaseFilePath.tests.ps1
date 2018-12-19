$here = $PSScriptRoot

$modulePath = "$here\..\..\.."
$moduleName = Split-Path -Path $modulePath -Leaf

InModuleScope $moduleName {
    It 'Should Throw when ESE is used and extension is .mdb' {
        { Assert-DSCPullServerDatabaseFilePath -Type ESE -File 'devices.mdb' } |
            Should -Throw
    }

    It 'Should not throw when ESE is used and extension is .edb' {
        { Assert-DSCPullServerDatabaseFilePath -Type ESE -File 'devices.edb' } |
            Should -Not -Throw
    }

    It 'Should Throw when MDB is used and extension is .edb' {
        { Assert-DSCPullServerDatabaseFilePath -Type MDB -File 'devices.edb' } |
            Should -Throw
    }

    It 'Should not throw when MDB is used and extension is .mdb' {
        { Assert-DSCPullServerDatabaseFilePath -Type MDB -File 'devices.mdb' } |
            Should -Not -Throw
    }
}
