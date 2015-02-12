function Setup-Mock {
    [cmdletbinding(DefaultParameterSetName="Method")]
    param (
        [parameter(ValueFromPipeline)]
        [psobject]$Mock,

        [SetupType]$Type = ([SetupType]::Method),

        [parameter(position=1)]
        [alias("m", "Member", "Method", "Note", "Property")]
        [string]$MemberName,

        [parameter(position=2, ParameterSetName="Method")]
        [alias("e")]
        [func[object,bool][]]$Expectations = (New-Object 'func[object, bool][]'(0)),

        [parameter(position=2, ParameterSetName="Property")]
        [object]$defaultValue,

        [parameter()]
        [alias("p")]
        [switch]$PassThru
    )

    Guard-ArgumentIsPSClassInstance 'Mock' $Mock 'GpClass.Mock'
    Guard-ArgumentNotNullOrEmpty 'MemberName' $MemberName
    Guard-ArgumentNotNull 'Expectations' $Expectations
    Guard-ArgumentNotNull 'Type' $Type

    $member = $Mock._originalClass.__Members[$MemberName]
    if($member -eq $null) {
        throw (new-object PSMockException("Member with name: $MemberName cannot be found to mock!"))
    }

    $setupInfo = $null

    switch($Type) {
        ([SetupType]::Method) {
            if($member -isnot [System.Management.Automation.PSScriptMethod]) {
                throw (new-object PSMockException(("Member provided {0} is not a PSScriptMethod." -f $MemberName)))

                $setupInfo = New-PSClassInstance 'PSClass.Mock.MethodSetupInfo' -ArgumentList @(
                    $MemberName,
                    $Expectations
                )

                if($Mock._mockedMethods[$MemberName] -eq $null) {
                    $Mock._mockedMethods[$MemberName] = New-Object System.Collections.ArrayList
                }

                [Void]$Mock._mockedMethods[$MemberName].Add($setupInfo)
            }
        }

        ([SetupType]::Get) {
            if($member -isnot [System.Management.Automation.PSNoteProperty] -and $member -isnot [System.Management.Automation.PSScriptProperty]) {
                throw (new-object PSMockException(("Member provided {0} is not a PSScriptProperty or PSNoteProperty." -f $MemberName)))
            }
        }

        ([SetupType]::Set) {
            if($member -isnot [System.Management.Automation.PSNoteProperty] -and $member -isnot [System.Management.Automation.PSScriptProperty]) {
                throw (new-object PSMockException(("Member provided {0} is not a PSScriptProperty or PSNoteProperty." -f $MemberName)))
            }
        }

        default {
            throw (new-object PSMockException(("Unknown setup type: {0}" -f $Type)))
        }
    }

    if($PassThru) {
        return $setupInfo
    }

    if($member -is [System.Management.Automation.PSNoteProperty] `
        -or $member -is [System.Management.Automation.PSScriptProperty]) {

        if(-not $this._originalClass.__Properties.ContainsKey($MemberName) -and `
            -not $this._originalClass.__Notes.ContainsKey($MemberName)) {
            throw (new-object PSMockException("Note or Property with name: $MemberName cannot be found to mock!"))
        }

        $originalProperty = $this.Object.psobject.properties.Item($MemberName)

        $getter = { return $returnObjectOrMethodDefinition }.GetNewClosure()

        if($callbackValue -eq $null) {
            $setter = {}
        } else {
            $setter = {param($a) $callbackValue.Value = $a}.GetNewClosure()
        }

        $member = new-object management.automation.PSScriptProperty $MemberName,$getter,$setter
        $this.Object.psobject.properties.remove($MemberName)
        [Void]$this.Object.psobject.properties.add($member)
    }


}