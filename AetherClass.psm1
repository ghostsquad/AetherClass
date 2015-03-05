$ErrorActionPrefence = "Stop"
Set-StrictMode -Version Latest

$here = Split-Path -Parent $MyInvocation.MyCommand.Path

[Void](Add-Type -Path (Join-Path $here 'AetherClass.dll'))

# All
[Void](Add-TypeAccelerator -Name RegexOptions -Type ([System.Text.RegularExpressions.RegexOptions]))
[Void](Add-TypeAccelerator -Name Resources -Type ([Aether.Class.Properties.Resources]))

# PSClass
[Void](Add-TypeAccelerator -Name PSClassException -Type ([Aether.Class.PSClassException]))
[Void](Add-TypeAccelerator -Name PSClassTypeAttribute -Type ([Aether.Class.PSClassTypeAttribute]))

# PSClassMock
[Void](Add-TypeAccelerator -Name InvocationType -Type ([Aether.Class.Mock.InvocationType]))
[Void](Add-TypeAccelerator -Name Times -Type ([Aether.Class.Mock.Times]))
[Void](Add-TypeAccelerator -Name Range -Type ([Aether.Class.Mock.Range]))
[Void](Add-TypeAccelerator -Name PSMockException -Type ([Aether.Class.Mock.PSMockException]))
[Void](Add-TypeAccelerator -Name ExceptionReason -Type ([Aether.Class.Mock.ExceptionReason]))

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
. $here\functions\ObjectIs-PSClassInstance.ps1
. $here\functions\FormatCallCount.ps1
. $here\functions\FormatInvocation.ps1
. $here\functions\AssertMemberType.ps1

Export-ModuleMember -Function ItIs
Export-ModuleMember -Function *-*