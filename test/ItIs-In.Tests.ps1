$here = Split-Path -Parent $MyInvocation.MyCommand.Path
# here : /branch/tests/Poshbox.Test
. "$here\..\TestCommon.ps1"

Describe 'ItIs-In' {
    It 'returns GpClass.Mock.Expression' {
        $actualResult = ItIs-In @()
        (ObjectIs-PSClassInstance $actualResult -PSClassName 'GpClass.Mock.Expression') | Should Be $true
    }

    It 'has accurate representation of provided expression when ToString()' {
        $actualResult = ItIs-In @(1..2)
        $actualResult.ToString() | Should Be 'ItIs-In{Items=1 2}'
    }

    It 'can determine if input object is in collection' {
        $a = 1
        $actualResult = ItIs-In @(1..2)
        $actualResult.Predicate.Invoke($a) | Should Be $true
    }

    It 'can determine if unexpected input object is in collection' {
        $a = 3
        $actualResult = ItIs-In @(1..2)
        $actualResult.Predicate.Invoke($a) | Should Be $false
    }

    It 'can determine if reference object is in collection' {
        $a = new-psobject
        $actualResult = ItIs-In @("foo", $a)
        $actualResult.Predicate.Invoke($a) | Should Be $true
    }

    It 'can determine if unexpected reference object is in collection' {
        $a = new-psobject
        $actualResult = ItIs-In @("foo", "bar")
        $actualResult.Predicate.Invoke($a) | Should Be $false
    }

}