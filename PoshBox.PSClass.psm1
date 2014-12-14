$ErrorActionPrefence = "Stop"
Set-StrictMode -Version Latest

if((Get-Module PoshBox.Core -ListAvailable) -and -not (Get-Module PoshBox.Core)){
    Import-Module PoshBox.Core -Global
} else {
    Throw (New-Object System.InvalidOperationException("Dependency PoshBox.Core Module not found."))
}

$here = Split-Path -Parent $MyInvocation.MyCommand.Path

. $here\New-PSClass.ps1
. $here\New-PSClassMock.ps1

Export-ModuleMember -Function *-*