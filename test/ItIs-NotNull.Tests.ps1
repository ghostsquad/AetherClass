$here = Split-Path -Parent $MyInvocation.MyCommand.Path
# here : /branch/tests/Poshbox.Test
. "$here\..\TestCommon.ps1"

Describe 'ItIs-NotNull' {
    It 'can determine if input object (string) is not null' {
        $a = "foo"
        $actualFunc = ItIs-NotNull
        $actualFunc.Invoke($a) | Should Be $true
    }

    It 'can determine if input object (reference type) is not null' {
        $a = new-psobject
        $actualFunc = ItIs-NotNull
        $actualFunc.Invoke($a) | Should Be $true
    }

    It 'can determine if unexpected input object is not in collection' {
        $a = $null
        $actualFunc = ItIs-NotNull
        $actualFunc.Invoke($a) | Should Be $false
    }
}