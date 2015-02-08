$here = Split-Path -Parent $MyInvocation.MyCommand.Path
# here : /branch/tests/Poshbox.Test
. "$here\..\TestCommon.ps1"

Describe 'ItIs' {
    It 'can determine that inputobject is same reference is expected' {
        $a = new-psobject
        $actualFunc = ItIs $a
        $actualFunc.Invoke($a) | Should Be $true
    }

    It 'can determine that inputobject is diferrent reference than expected' {
        $a = new-psobject
        $b = new-psobject
        $actualFunc = ItIs $a
        $actualFunc.Invoke($b) | Should Be $false
    }

    It 'can compare strings that are same' {
        $a = 'i am a string'
        $b = 'i am a string'
        $actualFunc = ItIs $a
        $actualFunc.Invoke($b) | Should Be $true
    }

    It 'can compare strings that are different' {
        $a = 'i am a string'
        $b = 'i am a different string'
        $actualFunc = ItIs $a
        $actualFunc.Invoke($b) | Should Be $false
    }
}