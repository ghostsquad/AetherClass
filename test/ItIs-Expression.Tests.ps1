$here = Split-Path -Parent $MyInvocation.MyCommand.Path
# here : /branch/tests/Poshbox.Test
. "$here\..\TestCommon.ps1"

Describe 'ItIs-Expression' {
    It 'returns Aether.Class.Mock.Expression' {
        $actualResult = ItIs-Expression {}
        (ObjectIs-PSClassInstance $actualResult -PSClassName 'Aether.Class.Mock.Expression') | Should Be $true
    }

    It 'has accurate representation of provided expression when ToString()' {
        $sb = {param($a) return $true}
        $actualResult = ItIs-Expression $sb
        $actualResult.ToString() | Should Be $sb.ToString()
    }

    It 'returns a func[object, bool] from scripblock' {
        $sb = {param($a) return $true}
        $actualResult = ItIs-Expression $sb
        $actualResult.Predicate -is [func[object, bool]] | Should Be $true
    }

    It 'returns a func[object, bool] from func[object, bool]' {
        $actualResult = ItIs-Expression {param($a) return $true}
        $actualResult.Predicate -is [func[object, bool]] | Should Be $true
    }

    It 'returns original expression in func[object, bool] form' {
        $actualResult = ItIs-Expression {return $true}
        $actualResult.Predicate.Invoke($null) | Should Be $true
    }
}