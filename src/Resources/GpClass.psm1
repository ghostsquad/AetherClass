$ErrorActionPrefence = "Stop"
Set-StrictMode -Version Latest

$here = Split-Path -Parent $MyInvocation.MyCommand.Path

[Void](Add-Type -Path (Join-Path $here 'GpClass.dll'))

. $here\functions\Attach-PSClassConstructor.ps1
. $here\functions\Attach-PSClassMethod.ps1
. $here\functions\Attach-PSClassNote.ps1
. $here\functions\Attach-PSClassProperty.ps1
. $here\functions\Get-PSClass.ps1
. $here\functions\Guard-ArgumentIsPSClassDefinition.ps1
. $here\functions\Guard-ArgumentIsPSClassInstance.ps1
. $here\functions\ItIs.ps1
. $here\functions\ItIs-Any.ps1
. $here\functions\ItIs-Expression.ps1
. $here\functions\ItIs-In.ps1
. $here\functions\ItIs-InRange.ps1
. $here\functions\ItIs-NotIn.ps1
. $here\functions\ItIs-NotNull.ps1
. $here\functions\ItIs-Regex.ps1
. $here\functions\New-PSClass.ps1
. $here\functions\New-PSClassInstance.ps1
. $here\functions\New-PSClassMock.ps1
. $here\functions\Setup-Mock.ps1
. $here\functions\Setup-MockCallback.ps1
. $here\functions\Setup-MockReturn.ps1

[Void](Add-TypeAccelerator -Name Times -Type ([GpClass.Moq.Times]))
[Void](Add-TypeAccelerator -Name Range -Type ([GpClass.Moq.Range]))
[Void](Add-TypeAccelerator -Name RegexOptions -Type ([System.Text.RegularExpressions.RegexOptions]))
[Void](Add-TypeAccelerator -Name PSClassException -Type ([GpClass.PSClassException]))
[Void](Add-TypeAccelerator -Name PSMockException -Type ([GpClass.PSMockException]))
[Void](Add-TypeAccelerator -Name PSClassTypeAttribute -Type ([GpClass.PSClassTypeAttribute]))
[Void](Add-TypeAccelerator -Name SetupType -Type ([GpClass.Mock.SetupType]))

Export-ModuleMember -Function ItIs
Export-ModuleMember -Function *-*