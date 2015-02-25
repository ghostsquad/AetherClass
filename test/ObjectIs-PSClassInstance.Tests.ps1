$here = Split-Path -Parent $MyInvocation.MyCommand.Path
# here : /branch/tests/Poshbox.Test
. "$here\..\TestCommon.ps1"

Describe 'ObjectIs-PSClassInstance' {
    It 'Returns true for Mock' {

    }
}