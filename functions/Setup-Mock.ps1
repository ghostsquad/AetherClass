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

    Guard-ArgumentIsPSClassInstance 'Mock' $Mock 'GpClass.Mock'

    $setupInfo = $null

    if($PSCmdlet.ParameterSetName -eq "Method") {
        Guard-ArgumentNotNullOrEmpty 'MethodName' $MethodName
        Guard-ArgumentNotNull 'Expectations' $Expectations

        $setupInfo = $Mock.Setup($MethodName, $Expectations)
    } else {
        Guard-ArgumentNotNullOrEmpty 'PropertyName' $PropertyName

        $setupInfo = $Mock.SetupProperty($PropertyName, $DefaultValue)
    }

    if($PassThru) {
        return $setupInfo
    }
}