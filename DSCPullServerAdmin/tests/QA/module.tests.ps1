$here = Split-Path -Parent $MyInvocation.MyCommand.Path

$modulePath = "$here\..\.."
$moduleName = Split-Path -Path $modulePath -Leaf


Describe 'General module control' -Tags 'FunctionalQuality' {

    It 'imports without errors' {
        { Import-Module -Name $modulePath -Force -ErrorAction Stop } | Should -Not -Throw
        Get-Module $moduleName | Should -Not -BeNullOrEmpty
    }

    It 'Removes without error' {
        { Remove-Module -Name $moduleName -ErrorAction Stop} | Should -Not -Throw
        Get-Module $moduleName | Should -BeNullOrEmpty
    }
}

function GetParsedFunction {
    param (
        $File
    )
    $AbstractSyntaxTree = [System.Management.Automation.Language.Parser]::
    ParseInput((Get-Content -raw $File.FullName), [ref]$null, [ref]$null)
    $AstSearchDelegate = { $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] }
    $AbstractSyntaxTree.FindAll( $AstSearchDelegate, $true ) |
        Where-Object Name -eq $File.BaseName
}

function GetFunctionHelp {
    param (
        $File
    )
    $ParsedFunction = GetParsedFunction -File $File
    $ParsedFunction.GetHelpContent()
}

$classes = Get-ChildItem -Path "$modulePath\classes\*.ps1" | ForEach-Object -Process {
    @{
        File = $_
        Base = $_.BaseName
    }
}

$privateFunctions = Get-ChildItem -Path "$modulePath\private\*.ps1" | ForEach-Object -Process {
    @{
        File = $_
        Base = $_.BaseName
    }
}

$publicFunctions = Get-ChildItem -Path "$modulePath\public\*.ps1" | ForEach-Object -Process {
    @{
        File = $_
        Base = $_.BaseName
        Help = GetFunctionHelp -File $_
        Parsed = GetParsedFunction -File $_
    }
}

$allModuleFunctions = $privateFunctions + $publicFunctions + $classes

if (Get-Command -Name Invoke-ScriptAnalyzer -ErrorAction SilentlyContinue) {
    $scriptAnalyzerRules = Get-ScriptAnalyzerRule
} else {
    if ($ErrorActionPreference -ne 'Stop') {
        Write-Warning -Message 'ScriptAnalyzer not found!'
    } else {
        Throw 'ScriptAnalyzer not found!'
    }
}

Describe 'Quality for functions'-Tags 'TestQuality' {
    It '<base> has a unit test' -TestCases $allModuleFunctions {
        param (
            $File
        )
        Get-ChildItem -Path "$modulePath\tests\Unit\" -Recurse -Include "$($File.BaseName).tests.ps1" | Should -Not -BeNullOrEmpty
    }
        
    if ($scriptAnalyzerRules) {
        It 'Script Analyzer for <base>' -TestCases $allModuleFunctions {
            param (
                $File
            )
            foreach ($scriptAnalyzerRule in $scriptAnalyzerRules) {
                $PSSAResult = (Invoke-ScriptAnalyzer -Path $File.FullName -IncludeRule $scriptAnalyzerRule)
                ($PSSAResult | Format-List | Out-String) | Should -BeNullOrEmpty
            }
        }
    }
}



Describe "Help for public functions" -Tags 'helpQuality' {
    It '<base> Has a SYNOPSIS' -TestCases $publicFunctions {
        param (
            $Help
        )
        $Help.Synopsis | Should -Not -BeNullOrEmpty
    }

    It '<base> Has a Description, with length > 40' -TestCases $publicFunctions {
        param (
            $Help
        )
        $Help.Description.Length | Should -BeGreaterThan 40
    }

    It '<base> Has at least 1 example' -TestCases $publicFunctions {
        param (
            $File,
            $Help
        )
        $Help.Examples.Count | Should -BeGreaterThan 0 
        $Help.Examples[0] | Should -Match ([regex]::Escape($File.BaseName))
        $Help.Examples[0].Length | Should -BeGreaterThan ($File.BaseName.Length + 10)
    }

    foreach ($p in $publicFunctions) {
        $parameters = $p.Parsed.Body.ParamBlock.Parameters.name.VariablePath.Foreach{$_.ToString() }
        foreach ($parameter in $parameters) {
            It "<base> Has help for Parameter: $parameter" -TestCases $p {
                param (
                    $Help
                )
                $Help.Parameters.($parameter.ToUpper())        | Should -Not -BeNullOrEmpty
                $Help.Parameters.($parameter.ToUpper()).Length | Should -BeGreaterThan 25
            }
        }
    }
}
