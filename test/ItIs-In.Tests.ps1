$here = Split-Path -Parent $MyInvocation.MyCommand.Path
# here : /branch/tests/Poshbox.Test
. "$here\..\TestCommon.ps1"

Describe 'ItIs-In' {
    It 'can determine if input object is in collection' {
        $a = 1
        $actualFunc = ItIs-In @(1..2)
        $actualFunc.Invoke($a) | Should Be $true
    }

    It 'can determine if unexpected input object is in collection' {
        $a = 3
        $actualFunc = ItIs-In @(1..2)
        $actualFunc.Invoke($a) | Should Be $false
    }

    It 'can determine if reference object is in collection' {
        $a = new-psobject
        $actualFunc = ItIs-In @("foo", $a)
        $actualFunc.Invoke($a) | Should Be $true
    }

    It 'can determine if unexpected reference object is in collection' {
        $a = new-psobject
        $actualFunc = ItIs-In @("foo", "bar")
        $actualFunc.Invoke($a) | Should Be $false
    }

}