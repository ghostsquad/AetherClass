# Performs a comparison of properties, notes, and methods.
# Ensures that the inputobject has AT LEAST all the members
# defined in the PSClass
function Guard-ArgumentIsPSClassDefinition {
    [cmdletbinding(DefaultParameterSetName='PSClass')]
    param (
        [Parameter(Position=0,ParameterSetName='PSClass')]
        [Parameter(Position=0,ParameterSetName='PSClassName')]
        [string]$ArgumentName,

        [Parameter(Position=1,ParameterSetName='PSClass')]
        [Parameter(Position=1,ParameterSetName='PSClassName')]
        [psobject]$InputObject
    )

    Guard-ArgumentNotNull $ArgumentName $InputObject

    $expectedTypeName = 'Aether.Class.PSClassDefinition'
    $foundClassInTypeNames = $false
    foreach($typeName in $InputObject.psobject.TypeNames) {
        if($typeName -eq $expectedTypeName) {
            $foundClassInTypeNames = $true
            break
        }
    }

    if(-not $foundClassInTypeNames) {
        throw (New-Object PSClassException(
            ('InputObject does not appear to be a PSClass Definition object. TypeName: {0} was not found in the objects TypeNames list.' -f $expectedTypeName)))
    }
}