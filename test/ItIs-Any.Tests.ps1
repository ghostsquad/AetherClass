$here = Split-Path -Parent $MyInvocation.MyCommand.Path
# here : /branch/tests/Poshbox.Test
. "$here\..\TestCommon.ps1"

Describe 'ItIs-Any' {
    It 'returns GpClass.Mock.Expression' {
        $actualResult = ItIs-Any ([object])
        (ObjectIs-PSClassInstance $actualResult -PSClassName 'GpClass.Mock.Expression') | Should Be $true
    }

    It 'has accurate representation of provided expression when ToString()' {
        $actualResult = ItIs-Any ([object])
        $actualResult.ToString() | Should Be 'ItIs-Any{Type=System.Object}'
    }

    It 'can determine if inputobject is assignable from expected type' {
        $a = (new-object system.collections.arraylist)
        $actualResult = ItIs-Any ([System.Collections.IEnumerable])
        $actualResult.Predicate.Invoke($a) | Should Be $true
    }

    It 'can determine if unexpected inputobject is assignable from expected type' {
        $a = (new-object system.collections.arraylist)
        $actualResult = ItIs-Any ([string])
        $actualResult.Predicate.Invoke($a) | Should Be $false
    }
}