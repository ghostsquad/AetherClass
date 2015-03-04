$here = Split-Path -Parent $MyInvocation.MyCommand.Path
# here : /branch/tests/Poshbox.Test
. "$here\..\TestCommon.ps1"

Describe 'ItIs-InRange' {
    It 'returns Aether.Class.Mock.Expression' {
        $actualResult = ItIs-InRange 1 2
        (ObjectIs-PSClassInstance $actualResult -PSClassName 'Aether.Class.Mock.Expression') | Should Be $true
    }

    It 'has accurate representation of provided expression when ToString()' {
        $actualResult = ItIs-InRange 1 1
        $actualResult.ToString() | Should Be 'ItIs-InRange{From=1, To=1}'
    }

    It 'can determine if input object is in expected range - inclusive default' {
        $a = 1
        $actualResult = ItIs-InRange 1 1
        $actualResult.Predicate.Invoke($a) | Should Be $true
    }

    It 'can determine if unexpected input object is in expected range - inclusive default' {
        $a = 3
        $actualResult = ItIs-InRange 1 2
        $actualResult.Predicate.Invoke($a) | Should Be $false
    }

    It 'can determine if input object is in expected range - exclusive' {
        $a = 2
        $actualResult = ItIs-InRange 1 3 ([Range]::Exclusive)
        $actualResult.Predicate.Invoke($a) | Should Be $true
    }

    It 'can determine if unexpected input object is in expected range - exclusive' {
        $a = 1
        $actualResult = ItIs-InRange 1 1 ([Range]::Exclusive)
        $actualResult.Predicate.Invoke($a) | Should Be $false
    }

}