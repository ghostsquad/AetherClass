$here = Split-Path -Parent $MyInvocation.MyCommand.Path
# here : /branch/tests/Poshbox.Test
. "$here\..\TestCommon.ps1"

Describe 'ItIs-NotIn' {
    It 'can determine if input object is not in collection' {
        $a = 3
        $actualFunc = ItIs-NotIn @(1..2)
        $actualFunc.Invoke($a) | Should Be $true
    }

    It 'can determine if unexpected input object is not in collection' {
        $a = 2
        $actualFunc = ItIs-NotIn @(1..2)
        $actualFunc.Invoke($a) | Should Be $false
    }

    It 'can determine if reference object is not in collection' {
        $a = new-psobject
        $actualFunc = ItIs-NotIn @("foo", "bar")
        $actualFunc.Invoke($a) | Should Be $true
    }

    It 'can determine if unexpected reference object is not in collection' {
        $a = new-psobject
        $actualFunc = ItIs-NotIn @("foo", $a)
        $actualFunc.Invoke($a) | Should Be $false
    }

}