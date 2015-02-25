function ObjectIs-PSClassInstance {
    [cmdletbinding(DefaultParameterSetName='PSClass')]
    param (
        [Parameter(Position=0)]
        [psobject]$InputObject,

        [Parameter(Position=1, ParameterSetName='PSClass')]
        [psobject]$PSClass,

        [Parameter(Position=1, ParameterSetName='PSClassName')]
        [string]$PSClassName
    )

    try {
        if($PSCmdlet.ParameterSetName -eq 'PSClassName') {
            if([string]::IsNullOrEmpty($PSClassName)) {
                Write-Debug 'Parameter: PSClassName is null or empty'
                return $false
            }
            $PSClass = Get-PSClass $PSClassName
            if($PSClass -eq $null) {
                Write-Debug ('The PSClass cannot be found: {0}' -f $PSClassName)
                return $false
            }
        } else {
            if($PSClass -eq $null) {
                Write-Debug 'Parameter: PSClass is null'
                return $false
            }

            $PSClassName = $PSClass.__ClassName

            if ($PSClassName -eq $null) {
                $msg = 'The PSClass object appears to be invalid. Property __ClassName does not exist or is null'
                Write-Debug $msg
                return $false
            }
        }

        if($InputObject -eq $null) {
            Write-Debug 'InputObject is null'
            return $false
        }

        $typeNameFound = $false
        foreach($typeName in $InputObject.psobject.TypeNames) {
            if($typeName -eq $PSClassName) {
                $typeNameFound = $true
            }
        }

        if(-not $typeNameFound) {
            Write-Debug ('typeName {0} was not found in TypeList' -f $PSClassName)
            return $false
        }

        $isMock = $InputObject.psobject.properties['____Mock____'] -ne $null
        if($isMock) { Write-Debug 'InputObject is a PSClassMock instance' }

        foreach($classMember in $PSClass.__Members.Values) {
            $memberName = $classMember.Name
            $objectMember = $InputObject.psobject.members[$memberName]

            $classMemberType = $classMember.GetType()
            $objectMemberType = $objectMember.GetType()

            if($isMock -and $classMemberType -eq [System.Management.Automation.PSPropertyInfo] `
                -and -not $objectMemberType -eq [System.Management.Automation.PSPropertyInfo]) {

                Write-Debug ('InputObject is a PSClassMock, and the class expects a derivative of PSPropertyInfo for member ''{0}''. Mock member type is {1}' -f `
                        $memberName, `
                        $objectMemberType)

                return $false
            }

            # compare member types
            # we could go further and compare parameters for method scripts and property getter/setter, but that seems like overkill
            # considering that the PSClass TypeName assertion prior to this
            if (-not $isMock -and $objectMember -ne $null -and $objectMemberType -ne $classMemberType) {
                Write-Debug ('Member type mismatch. Class has member {0} which is {1}, where as the object has a member with the same name which is {2}' -f `
                        $memberName, `
                        $classMemberType, `
                        $objectMemberType)

                return $false
            }
        }
    } catch {
        Write-Debug $_
        return $false
    }

    return $true
}