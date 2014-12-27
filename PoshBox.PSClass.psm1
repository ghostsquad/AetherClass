$ErrorActionPrefence = "Stop"
Set-StrictMode -Version Latest

$here = Split-Path -Parent $MyInvocation.MyCommand.Path

if(-not (Get-Module PoshBox.Core)){
    Import-Module "$here\..\PoshBox.Core" -Global -DisableNameChecking
}

. $here\Attach-PSClassConstructor.ps1
. $here\Attach-PSClassMethod.ps1
. $here\Attach-PSClassNote.ps1
. $here\Attach-PSClassProperty.ps1
. $here\New-PSClass.ps1
. $here\Get-PSClass.ps1
. $here\New-PSClassMock.ps1
. $here\Guard-ArgumentIsPSClass.ps1

Export-ModuleMember -Function *-*