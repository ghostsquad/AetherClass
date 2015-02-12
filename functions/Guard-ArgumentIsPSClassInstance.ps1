# Performs a comparison of properties, notes, and methods.
# Ensures that the inputobject has AT LEAST all the members
# defined in the PSClass
function Guard-ArgumentIsPSClassInstance {
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
        $ObjectIsPSClassInstance = ObjectIs-PSClassInstance -PSClassName $PSClassName
    } else {
        $ObjectIsPSClassInstance = ObjectIs-PSClassInstance -PSClass $PSClass
    }

    if(-not $ObjectIsPSClassInstance) {
        throw (New-Object PSClassException(
            ('InputObject does not appear have been created by New-PSClass.' -f $PSClass.__ClassName)))
    }
}