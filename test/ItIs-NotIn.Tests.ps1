$here = Split-Path -Parent $MyInvocation.MyCommand.Path
# here : /branch/tests/Poshbox.Test
. "$here\..\TestCommon.ps1"

Describe 'ItIs-NotIn' {
    It 'returns GpClass.Mock.Expression' {
        $actualResult = ItIs-NotIn @()
        (ObjectIs-PSClassInstance $actualResult -PSClassName 'GpClass.Mock.Expression') | Should Be $true
    }

    It 'has accurate representation of provided expression when ToString()' {
        $actualResult = ItIs-NotIn @(1..2)
        $actualResult.ToString() | Should Be 'ItIs-NotIn{Items=1 2}'
    }

    It 'can determine if input object is not in collection' {
        $a = 3
        $actualResult = ItIs-NotIn @(1..2)
        $actualResult.Predicate.Invoke($a) | Should Be $true
    }

    It 'can determine if unexpected input object is not in collection' {
        $a = 2
        $actualResult = ItIs-NotIn @(1..2)
        $actualResult.Predicate.Invoke($a) | Should Be $false
    }

    It 'can determine if reference object is not in collection' {
        $a = new-psobject
        $actualResult = ItIs-NotIn @("foo", "bar")
        $actualResult.Predicate.Invoke($a) | Should Be $true
    }

    It 'can determine if unexpected reference object is not in collection' {
        $a = new-psobject
        $actualResult = ItIs-NotIn @("foo", $a)
        $actualResult.Predicate.Invoke($a) | Should Be $false
    }

}