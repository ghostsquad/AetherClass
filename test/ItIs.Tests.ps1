$here = Split-Path -Parent $MyInvocation.MyCommand.Path
# here : /branch/tests/Poshbox.Test
. "$here\..\TestCommon.ps1"

Describe 'ItIs' {
    It 'returns Aether.Class.Mock.Expression' {
        $actualResult = ItIs 'foo'
        (ObjectIs-PSClassInstance $actualResult -PSClassName 'Aether.Class.Mock.Expression') | Should Be $true
    }

    It 'has accurate representation of provided expression when ToString()' {
        $actualResult = ItIs 'foo'
        $actualResult.ToString() | Should Be 'ItIs{InputObject=foo}'
    }

    It 'can determine that inputobject is same reference is expected' {
        $a = new-psobject
        $actualResult = ItIs $a
        $actualResult.Predicate.Invoke($a) | Should Be $true
    }

    It 'can determine that inputobject is diferrent reference than expected' {
        $a = new-psobject
        $b = new-psobject
        $actualResult = ItIs $a
        $actualResult.Predicate.Invoke($b) | Should Be $false
    }

    It 'can compare strings that are same' {
        $a = 'i am a string'
        $b = 'i am a string'
        $actualResult = ItIs $a
        $actualResult.Predicate.Invoke($b) | Should Be $true
    }

    It 'can compare strings that are different' {
        $a = 'i am a string'
        $b = 'i am a different string'
        $actualResult = ItIs $a
        $actualResult.Predicate.Invoke($b) | Should Be $false
    }
}