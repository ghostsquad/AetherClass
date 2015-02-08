$here = Split-Path -Parent $MyInvocation.MyCommand.Path
# here : /branch/tests/Poshbox.Test
. "$here\..\TestCommon.ps1"

Describe 'ItIs-Any' {
    It 'can determine if inputobject is assignable from expected type' {
        $a = (new-object system.collections.arraylist)
        $actualFunc = ItIs-Any ([System.Collections.IEnumerable])
        $actualFunc.Invoke($a) | Should Be $true
    }

    It 'can determine if unexpected inputobject is assignable from expected type' {
        $a = (new-object system.collections.arraylist)
        $actualFunc = ItIs-Any ([string])
        $actualFunc.Invoke($a) | Should Be $false
    }
}