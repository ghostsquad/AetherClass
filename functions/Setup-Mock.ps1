function Setup-Mock {
    [cmdletbinding(DefaultParameterSetName="Method")]
    param (
        [parameter(ValueFromPipeline)]
        [psobject]$Mock,

        [parameter(position=0, ParameterSetName="Method")]
        [alias('m', 'method')]
        [string]$MethodName,

        [parameter(position=0, ParameterSetName="Property")]
        [alias('p', 'prop', 'property')]
        [string]$PropertyName,


        [parameter(position=1, ParameterSetName="Method")]
        [alias("e")]
        [func[object,bool][]]$Expectations = @(),

        [parameter(position=1, ParameterSetName="Property")]
        [object]$DefaultValue,

        [switch]$PassThru
    )

    function GetMember {
        param (
            [string]$memberName
        )

        $member = $Mock._originalClass.__Members[$MemberName]
        if($member -eq $null) {
            throw (new-object PSMockException("Member with name: $MemberName cannot be found to mock!"))
        }

        return $member
    }

    Guard-ArgumentIsPSClassInstance 'Mock' $Mock 'GpClass.Mock'

    $setupInfo = $null

    if($PSCmdlet.ParameterSetName -eq "Method") {
        Guard-ArgumentNotNullOrEmpty 'MethodName' $MethodName
        Guard-ArgumentNotNull 'Expectations' $Expectations

        $member = GetMember $MethodName

        if($member -isnot [System.Management.Automation.PSScriptMethod]) {
            throw (new-object PSMockException(("Member {0} is not a PSScriptMethod." -f $MethodName)))
        }

        $setupInfo = New-PSClassInstance 'PSClass.Mock.MethodSetupInfo' -ArgumentList @(
            $MethodName,
            $Expectations
        )

        [Void]$Mock._mockedMethods[$MethodName].Add($setupInfo)
    } else {
        Guard-ArgumentNotNullOrEmpty 'PropertyName' $PropertyName
        $member = GetMember $MethodName

        if($member -isnot [System.Management.Automation.PSNoteProperty] -and $member -isnot [System.Management.Automation.PSScriptProperty]) {
            throw (new-object PSMockException(("Member {0} is not a PSScriptProperty or PSNoteProperty." -f $PropertyName)))
        }

        $setupInfo = New-PSClassInstance 'PSClass.Mock.PropertySetupInfo' -ArgumentList @(
            $PropertyName,
            $DefaultValue
        )

        [Void]$Mock._mockedProperties[$PropertyName].Add($setupInfo)
    }

    if($PassThru) {
        return $setupInfo
    }
}