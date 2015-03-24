$here = Split-Path -Parent $MyInvocation.MyCommand.Path
. "$here\..\TestCommon.ps1"

Describe 'New-PSClassInstance' {
    It 'handles an array starting with $null values correctly' {
        $className = [guid]::NewGuid().ToString()
        New-PSClass $className {
            note c

            constructor {
                param (
                    $a,
                    $b,
                    $c
                )

                $this.c = $c
            }
        }

        $actual = New-PSClassInstance $className -ArgumentList @(
            $null,
            $null,
            'myvalue'
        )

        $actual.c | Should Be 'myvalue'
    }
}