$ErrorActionPrefence = "Stop"
Set-StrictMode -Version Latest

$here = Split-Path -Parent $MyInvocation.MyCommand.Path

if(-not (Get-Module PoshBox.Core)){
    Import-Module "$here\..\PoshBox.Core" -Global -DisableNameChecking
}

. $here\New-PSClass.ps1
. $here\New-PSClassMock.ps1
. $here\Guard-ObjectIsPSClass.ps1

Export-ModuleMember -Function *-*