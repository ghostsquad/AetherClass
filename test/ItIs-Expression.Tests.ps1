$here = Split-Path -Parent $MyInvocation.MyCommand.Path
# here : /branch/tests/Poshbox.Test
. "$here\..\TestCommon.ps1"

Describe 'ItIs-Expression' {
    It 'returns a func[object, bool] from scripblock' {
        $sb = {param($a) return $true}
        $actual = ItIs-Expression $sb
        $actual -is [func[object, bool]] | Should Be $true
    }

    It 'returns a func[object, bool] from func[object, bool]' {
        [func[object, bool]]$func = {param($a) return $true}
        $actual = ItIs-Expression $func
        $actual -is [func[object, bool]] | Should Be $true
    }

    It 'returns original expression in func[object, bool] form' {
        $actual = ItIs-Expression {return $true}
        $actual.Invoke($null) | Should Be $true
    }
}