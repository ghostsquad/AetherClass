$ErrorActionPrefence = "Stop"
Set-StrictMode -Version Latest

if(-not (Get-Module PoshBox.Core)){
    Import-Module ..\PoshBox.Core -Global
}

$here = Split-Path -Parent $MyInvocation.MyCommand.Path

. $here\New-PSClass.ps1
. $here\New-PSClassMock.ps1

Export-ModuleMember -Function *-*