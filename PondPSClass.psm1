$ErrorActionPrefence = "Stop"
Set-StrictMode -Version Latest

$here = Split-Path -Parent $MyInvocation.MyCommand.Path

. $here\functions\Attach-PSClassConstructor.ps1
. $here\functions\Attach-PSClassMethod.ps1
. $here\functions\Attach-PSClassNote.ps1
. $here\functions\Attach-PSClassProperty.ps1
. $here\functions\New-PSClass.ps1
. $here\functions\Get-PSClass.ps1
. $here\functions\New-PSClassMock.ps1
. $here\functions\Guard-ArgumentIsPSClass.ps1

Export-ModuleMember -Function *-*