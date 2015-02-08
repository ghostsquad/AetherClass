$here = Split-Path -Parent $MyInvocation.MyCommand.Path
# here : /branch/tests/Poshbox.Test
. "$here\..\TestCommon.ps1"

Describe 'ItIs-InRange' {
    It 'can determine if input object is in expected range - inclusive default' {
        $a = 1
        $actualFunc = ItIs-InRange 1 1
        $actualFunc.Invoke($a) | Should Be $true
    }

    It 'can determine if unexpected input object is in expected range - inclusive default' {
        $a = 3
        $actualFunc = ItIs-InRange 1 2
        $actualFunc.Invoke($a) | Should Be $false
    }

    It 'can determine if input object is in expected range - exclusive' {
        $a = 2
        $actualFunc = ItIs-InRange 1 3 ([Range]::Exclusive)
        $actualFunc.Invoke($a) | Should Be $true
    }

    It 'can determine if unexpected input object is in expected range - exclusive' {
        $a = 1
        $actualFunc = ItIs-InRange 1 1 ([Range]::Exclusive)
        $actualFunc.Invoke($a) | Should Be $false
    }

}