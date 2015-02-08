$here = Split-Path -Parent $MyInvocation.MyCommand.Path
# here : /branch/tests/Poshbox.Test
. "$here\..\TestCommon.ps1"

Describe 'ItIs-Regex' {
    It 'can determine if expected string matches regex pattern' {
        $a = "foo"
        $actualFunc = ItIs-Regex '[foo]+'
        $actualFunc.Invoke($a) | Should Be $true
    }

    It 'can determine if unexpected string notmatches regex pattern' {
        $a = "bar"
        $actualFunc = ItIs-Regex '[foo]+'
        $actualFunc.Invoke($a) | Should Be $false
    }

    It 'can determine that input object is not a string' {
        $a = new-psobject
        $actualFunc = ItIs-Regex '[foo]+'
        $actualFunc.Invoke($a) | Should Be $false
    }
}