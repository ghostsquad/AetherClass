$here = Split-Path -Parent $MyInvocation.MyCommand.Path
# here : /branch/tests/Poshbox.Test
. "$here\..\TestCommon.ps1"

Describe 'ItIs-Regex' {
    It 'returns Aether.Class.Mock.Expression' {
        $actualResult = ItIs-Regex ''
        (ObjectIs-PSClassInstance $actualResult -PSClassName 'Aether.Class.Mock.Expression') | Should Be $true
    }

    It 'has accurate representation of provided expression when ToString()' {
        $actualResult = ItIs-Regex '[foo]+'
        $actualResult.ToString() | Should Be 'ItIs-Regex{Pattern=[foo]+}'
    }

    It 'can determine if expected string matches regex pattern' {
        $a = "foo"
        $actualResult = ItIs-Regex '[foo]+'
        $actualResult.Predicate.Invoke($a) | Should Be $true
    }

    It 'can determine if unexpected string notmatches regex pattern' {
        $a = "bar"
        $actualResult = ItIs-Regex '[foo]+'
        $actualResult.Predicate.Invoke($a) | Should Be $false
    }

    It 'can determine that input object is not a string' {
        $a = new-psobject
        $actualResult = ItIs-Regex '[foo]+'
        $actualResult.Predicate.Invoke($a) | Should Be $false
    }
}