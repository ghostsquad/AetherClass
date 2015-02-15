function Setup-MockReturn {
    [cmdletbinding()]
    param (
        [parameter(ValueFromPipeline)]
        [psobject]$SetupInfo,

        [parameter(position=0)]
        [object]$Returns

        [switch]$PassThru
    )

    Guard-ArgumentIsPSClassInstance 'SetupInfo' $SetupInfo 'GpClass.Mock.SetupInfo'

    $SetupInfo.Returns = $Returns

    if($PassThru) {
        return $SetupInfo
    }
}