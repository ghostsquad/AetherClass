$here = Split-Path -Parent $MyInvocation.MyCommand.Path
# here : /branch/tests/Poshbox.Test
. "$here\..\TestCommon.ps1"

Describe 'ItIs-NotNull' {
    It 'returns Aether.Class.Mock.Expression' {
        $actualResult = ItIs-NotNull
        (ObjectIs-PSClassInstance $actualResult -PSClassName 'Aether.Class.Mock.Expression') | Should Be $true
    }

    It 'has accurate representation of provided expression when ToString()' {
        $actualResult = ItIs-NotNull
        $actualResult.ToString() | Should Be 'ItIs-NotNull{}'
    }

    It 'can determine if input object (string) is not null' {
        $a = "foo"
        $actualResult = ItIs-NotNull
        $actualResult.Predicate.Invoke($a) | Should Be $true
    }

    It 'can determine if input object (reference type) is not null' {
        $a = new-psobject
        $actualResult = ItIs-NotNull
        $actualResult.Predicate.Invoke($a) | Should Be $true
    }

    It 'can determine if unexpected input object is not in collection' {
        $a = $null
        $actualResult = ItIs-NotNull
        $actualResult.Predicate.Invoke($a) | Should Be $false
    }
}