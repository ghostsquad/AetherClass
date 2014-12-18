# Performs a comparison of properties, notes, and methods.
# Ensures that the inputobject has AT LEAST all the members
# defined in the PSClass
function Guard-ObjectIsPSClass {
    param (
        [psobject]$InputObject,
        [psobject]$PSClass,
        [string]$PSClassName
    )

    Guard-ArgumentNotNull 'InputObject' $InputObject
    Guard-ArgumentValid 'PSClass/PSClassName' `
        'Provide only the PSClass definition object or the PSClassName (to be looked up in the PSClassContainer).' `
        ($PSClass -ne $null -and $PSClassName -ne $null)

    if($PSClassName -ne $null) {
        $PSClass = [PSClassContainer]::ClassDefinitions[$PSClassName]
    }

    $foundClassInTypeNames = $false
    foreach($typeName in $InputObject.psobject.TypeNames) {
        if($typeName -eq $) {
            $foundClassInTypeNames = $true
            break
        }
    }

    if(-not $foundClassInTypeNames) {
        throw (New-Object PSClassObjectDoesNotMatchException(
            ('InputObject does not appear have been created by New-PSClass, as the TypeName: {0} was not found.' -f $PSClass.__ClassName)))
    }



    Attach-PSNote $class __Notes @{}
    Attach-PSNote $class __Methods @{}
    Attach-PSNote $class __Properties @{}
}

if (-not ([System.Management.Automation.PSTypeName]'PSClassObjectDoesNotMatchException').Type)
{
    Add-Type -WarningAction Ignore -TypeDefinition @"
    using System;
    using System.Management.Automation;

    public class PSClassObjectDoesNotMatchException : Exception {
        public PSClassObjectDoesNotMatchException(string message)
            : base(message)
        {
        }

        public PSClassObjectDoesNotMatchException(string message, Exception inner)
            : base(message, inner)
        {
        }
    }
"@
}