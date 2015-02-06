# Performs a comparison of properties, notes, and methods.
# Ensures that the inputobject has AT LEAST all the members
# defined in the PSClass
function Guard-ArgumentIsPSClass {
    [cmdletbinding(DefaultParameterSetName='PSClass')]
    param (
        [Parameter(Position=0,ParameterSetName='PSClass')]
        [Parameter(Position=0,ParameterSetName='PSClassName')]
        [string]$ArgumentName,

        [Parameter(Position=1,ParameterSetName='PSClass')]
        [Parameter(Position=1,ParameterSetName='PSClassName')]
        [psobject]$InputObject,

        [Parameter(Position=2,ParameterSetName='PSClass')]
        [psobject]$PSClass,

        [Parameter(Position=2,ParameterSetName='PSClassName')]
        [string]$PSClassName
    )

    Guard-ArgumentNotNull $ArgumentName $InputObject

    if($PSCmdlet.ParameterSetName -eq 'PSClassName') {
        Guard-ArgumentNotNull 'PSClassName' $PSClassName
        $PSClass = Get-PSClass $PSClassName
    } else {
        Guard-ArgumentNotNull 'PSClass' $PSClass
        $PSClassName = $PSClass.__ClassName
    }

    $foundClassInTypeNames = $false
    foreach($typeName in $InputObject.psobject.TypeNames) {
        if($typeName -eq $PSClassName) {
            $foundClassInTypeNames = $true
            break
        }
    }

    if(-not $foundClassInTypeNames) {
        throw (New-Object PSClassObjectDoesNotMatchException(
            ('InputObject does not appear have been created by New-PSClass, as the TypeName: {0} was not found in the objects TypeNames list.' -f $PSClass.__ClassName)))
    }

    # Compare Members
    foreach($classMember in $PSClass.__Members.Values) {
        $memberName = $classMember.Name
        $objectMember = $InputObject.psobject.members[$memberName]
        # compare member types
        # we could go further and compare parameters for method scripts and property getter/setter, but that seems like overkill
        # considering that the PSClass TypeName assertion prior to this
        if ($objectMember -ne $null -and $objectMember.GetType() -ne $classMember.GetType()) {
            throw (New-Object PSClassObjectDoesNotMatchException(
                ('Member type mismatch. Class has member {0} which is {1}, where as the object has a member with the same name which is {2}' -f `
                    $memberName, `
                    $psMemberInfo.GetType(), `
                    $objectMember.GetType())))
        }
    }
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